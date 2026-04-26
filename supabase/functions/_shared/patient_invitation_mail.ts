import {
  formatSessionRangeText,
  PatientInvitationFlow,
  renderPatientInvitationEmailTemplate,
} from './email_templates/patient_invitation.ts';
import { dispatchMail } from './mail_dispatcher.ts';
import { MailFlowError } from './mail_flow_errors.ts';

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

type ServiceRoleClient = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: unknown) => any;
      maybeSingle: <T>() => Promise<{ data: T | null; error: unknown }>;
    };
  };
};

export async function sendPatientInvitationMail(params: {
  supabase: ServiceRoleClient;
  userId: string;
  requestId: string;
  invitationId: string;
  registrationBaseUrl: string;
  recipientTimezone: string;
}): Promise<void> {
  const { supabase, userId, requestId, invitationId, registrationBaseUrl, recipientTimezone } = params;

  if (!invitationId || !registrationBaseUrl) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Payload undangan pasien belum lengkap.');
  }

  const { data: invitation, error: invitationError } = await supabase
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
    throw new MailFlowError(404, 'BAD_REQUEST', 'Data undangan pasien tidak ditemukan.');
  }

  if (!invitation.invited_by_membership_id) {
    throw new MailFlowError(403, 'FORBIDDEN', 'Undangan pasien tidak memiliki membership pengundang yang valid.');
  }

  const { data: membership } = await supabase
    .from('clinic_memberships')
    .select('id')
    .eq('id', invitation.invited_by_membership_id)
    .eq('user_id', userId)
    .eq('is_active', true)
    .maybeSingle<{ id: string }>();

  if (!membership) {
    throw new MailFlowError(403, 'FORBIDDEN', 'Undangan pasien tidak dapat dikirim dari akun ini.');
  }

  const { data: clinic } = await supabase
    .from('clinics')
    .select('name')
    .eq('id', invitation.clinic_id)
    .maybeSingle<{ name: string | null }>();

  const email = invitation.email.trim().toLowerCase();
  const flow = invitation.flow;
  const token = invitation.token.trim();
  const clinicName = clinic?.name?.trim() || 'Catatan Psikolog';
  const sessionTimezone = asTrimmedString(invitation.session_timezone) || 'Asia/Jakarta';
  const displayTimezone = recipientTimezone || sessionTimezone;
  const sessionStartAt = invitation.session_start_at ? new Date(invitation.session_start_at) : null;
  const sessionEndAt = invitation.session_end_at ? new Date(invitation.session_end_at) : null;

  if (!isValidEmail(email) || !isValidFlow(flow)) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Data undangan pasien tidak valid.');
  }

  if (
    !sessionStartAt ||
    !sessionEndAt ||
    Number.isNaN(sessionStartAt.getTime()) ||
    Number.isNaN(sessionEndAt.getTime())
  ) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Jadwal undangan pasien tidak valid.');
  }

  if (flow !== 'info_only' && !token) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Payload link undangan pasien belum lengkap.');
  }

  let registrationUrl: string | undefined;
  let expiresText: string | undefined;
  if (flow !== 'info_only') {
    registrationUrl = new URL(`/register?token=${encodeURIComponent(token)}`, registrationBaseUrl).toString();
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
}
