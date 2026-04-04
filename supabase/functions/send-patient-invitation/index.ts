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
  email?: unknown;
  flow?: unknown;
  token?: unknown;
  registration_base_url?: unknown;
  expires_at?: unknown;
  clinic_name?: unknown;
  session_start_at?: unknown;
  session_end_at?: unknown;
  session_timezone?: unknown;
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
    const email = asTrimmedString(payload.email).toLowerCase();
    const flow = asTrimmedString(payload.flow);
    const token = asTrimmedString(payload.token);
    const registrationBaseUrl = asTrimmedString(payload.registration_base_url);
    const expiresAtRaw = asTrimmedString(payload.expires_at);
    const clinicName = asTrimmedString(payload.clinic_name);
    const sessionStartAtRaw = asTrimmedString(payload.session_start_at);
    const sessionEndAtRaw = asTrimmedString(payload.session_end_at);
    const sessionTimezone = asTrimmedString(payload.session_timezone) || 'Asia/Jakarta';
    const recipientTimezone = asTrimmedString(payload.recipient_timezone) || sessionTimezone;

    if (!email || !flow || !clinicName || !sessionStartAtRaw || !sessionEndAtRaw) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload undangan pasien belum lengkap.',
      });
    }

    if (!isValidEmail(email)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Alamat email undangan tidak valid.',
      });
    }

    if (!isValidFlow(flow)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Flow undangan pasien tidak valid.',
      });
    }

    const sessionStartAt = new Date(sessionStartAtRaw);
    const sessionEndAt = new Date(sessionEndAtRaw);
    if (
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
      const expiresAt = expiresAtRaw ? new Date(expiresAtRaw) : null;
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
        recipientTimezone,
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
