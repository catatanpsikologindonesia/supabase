import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { requirePortalRole } from '../_shared/auth.ts';
import {
  formatSessionRangeText,
  PatientInvitationFlow,
  renderPatientInvitationEmailTemplate,
} from '../_shared/email_templates/patient_invitation.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';

type PatientInvitationPayload = {
  invitation_id?: unknown;
  registration_base_url?: unknown;
  recipient_timezone?: unknown;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidFlow(value: string): value is PatientInvitationFlow {
  return (
    value === 'registration_required' ||
    value === 'consent_required' ||
    value === 'info_only'
  );
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);

  if (req.method !== 'POST') {
    return jsonResponse({
      req,
      requestId,
      status: 400,
      success: false,
      code: 'BAD_REQUEST',
      message: 'Method tidak didukung.',
    });
  }

  try {
    const auth = await requirePortalRole(req);
    if (!auth.ok) {
      return jsonResponse({
        req,
        requestId,
        status: auth.status,
        success: false,
        code: auth.code,
        message: auth.message,
      });
    }

    const payload = (await req.json()) as PatientInvitationPayload;
    const invitationId = asTrimmedString(payload.invitation_id);
    const registrationBaseUrl = asTrimmedString(payload.registration_base_url);
    const recipientTimezone = asTrimmedString(payload.recipient_timezone);

    if (!invitationId || !registrationBaseUrl) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload undangan pasien belum lengkap.',
      });
    }

    const { data: invitation, error: invitationError } = await auth.supabase
      .from('patient_invitations')
      .select(
        'id, email, token, expires_at, flow, clinic_id, invited_by_membership_id, session_start_at, session_end_at, session_timezone',
      )
      .eq('id', invitationId)
      .maybeSingle<{
        id: string;
        email: string;
        token: string;
        expires_at: string;
        flow: PatientInvitationFlow;
        clinic_id: string;
        invited_by_membership_id: string | null;
        session_start_at: string | null;
        session_end_at: string | null;
        session_timezone: string | null;
      }>();

    if (invitationError || !invitation) {
      return jsonResponse({
        req,
        requestId,
        status: 404,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Data undangan pasien tidak ditemukan.',
      });
    }

    if (!invitation.invited_by_membership_id) {
      return jsonResponse({
        req,
        requestId,
        status: 403,
        success: false,
        code: 'FORBIDDEN',
        message: 'Undangan pasien tidak memiliki membership pengundang yang valid.',
      });
    }

    const { data: membership } = await auth.supabase
      .from('clinic_memberships')
      .select('id')
      .eq('id', invitation.invited_by_membership_id)
      .eq('user_id', auth.userId)
      .eq('is_active', true)
      .maybeSingle<{ id: string }>();

    if (!membership) {
      return jsonResponse({
        req,
        requestId,
        status: 403,
        success: false,
        code: 'FORBIDDEN',
        message: 'Undangan pasien tidak dapat dikirim dari akun ini.',
      });
    }

    const { data: clinic } = await auth.supabase
      .from('clinics')
      .select('name')
      .eq('id', invitation.clinic_id)
      .maybeSingle<{ name: string | null }>();

    const email = invitation.email.trim().toLowerCase();
    const flow = invitation.flow;
    const token = invitation.token.trim();
    const clinicName = clinic?.name?.trim() || 'Catatan Psikolog';
    const sessionTimezone = (invitation.session_timezone ?? '').trim() || 'Asia/Jakarta';
    const displayTimezone = recipientTimezone || sessionTimezone;
    const sessionStartAt = invitation.session_start_at ? new Date(invitation.session_start_at) : null;
    const sessionEndAt = invitation.session_end_at ? new Date(invitation.session_end_at) : null;

    if (!isValidEmail(email) || !isValidFlow(flow)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Data undangan pasien tidak valid.',
      });
    }

    if (
      !sessionStartAt ||
      !sessionEndAt ||
      Number.isNaN(sessionStartAt.getTime()) ||
      Number.isNaN(sessionEndAt.getTime())
    ) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Jadwal undangan pasien tidak valid.',
      });
    }

    if (flow !== 'info_only' && (!token || !registrationBaseUrl)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload link undangan pasien belum lengkap.',
      });
    }

    let registrationUrl: string | undefined;
    let expiresText: string | undefined;
    if (flow !== 'info_only') {
      registrationUrl = new URL(`/register/${token}`, registrationBaseUrl).toString();
      const expiresAt = invitation.expires_at ? new Date(invitation.expires_at) : null;
      expiresText =
        expiresAt && !Number.isNaN(expiresAt.getTime())
          ? `Link ini berlaku sampai ${expiresAt.toLocaleString('id-ID', {
              timeZone: 'Asia/Jakarta',
            })}.`
          : 'Link ini memiliki masa berlaku terbatas.';
    }

    const renderedEmail = renderPatientInvitationEmailTemplate({
      flow,
      clinicName,
      registrationUrl,
      expiresText,
      sessionText: formatSessionRangeText(
        sessionStartAt,
        sessionEndAt,
        displayTimezone,
      ),
    });

    await dispatchMail({
      requestId,
      to: email,
      subject: renderedEmail.subject,
      html: renderedEmail.html,
    });

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Email undangan pasien berhasil dikirim.',
    });
  } catch (error) {
    console.error('[send-patient-invitation]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Pengiriman email undangan pasien gagal.',
    });
  }
});
