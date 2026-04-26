import { renderReferralPinEmailTemplate } from './email_templates/referral_pin.ts';
import { dispatchMail } from './mail_dispatcher.ts';
import { MailFlowError } from './mail_flow_errors.ts';

type ServiceRoleClient = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: unknown) => any;
      maybeSingle: <T>() => Promise<{ data: T | null; error: unknown }>;
    };
  };
};

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export async function sendReferralPinMail(params: {
  supabase: ServiceRoleClient;
  userId: string;
  requestId: string;
  referralId: string;
  portalBaseUrl: string;
}): Promise<void> {
  const { supabase, userId, requestId, referralId, portalBaseUrl } = params;

  if (!referralId || !portalBaseUrl) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Payload email PIN rujukan belum lengkap.');
  }

  const { data: referral, error: referralError } = await supabase
    .from('referrals_and_feedback')
    .select('id, patient_id, destination, secure_pin, expires_at, practitioner_membership_id')
    .eq('id', referralId)
    .maybeSingle<{
      id: string;
      patient_id: string;
      destination: string;
      secure_pin: string;
      expires_at: string;
      practitioner_membership_id: string | null;
    }>();

  if (referralError || !referral) {
    throw new MailFlowError(404, 'BAD_REQUEST', 'Data referral tidak ditemukan.');
  }

  if (!referral.practitioner_membership_id) {
    throw new MailFlowError(403, 'FORBIDDEN', 'Referral tidak memiliki practitioner membership yang valid.');
  }

  const { data: membership } = await supabase
    .from('clinic_memberships')
    .select('id')
    .eq('id', referral.practitioner_membership_id)
    .eq('user_id', userId)
    .eq('is_active', true)
    .maybeSingle<{ id: string }>();

  if (!membership) {
    throw new MailFlowError(403, 'FORBIDDEN', 'Referral tidak dapat dikirim dari akun ini.');
  }

  const { data: patient, error: patientError } = await supabase
    .from('patients')
    .select('full_name, email')
    .eq('id', referral.patient_id)
    .maybeSingle<{ full_name: string | null; email: string | null }>();

  if (patientError || !patient) {
    throw new MailFlowError(404, 'BAD_REQUEST', 'Data pasien referral tidak ditemukan.');
  }

  const email = patient.email?.trim().toLowerCase() ?? '';
  const patientName = patient.full_name?.trim() ?? '';
  const destination = referral.destination?.trim() ?? '';
  const pin = referral.secure_pin?.trim() ?? '';

  if (!email || !patientName || !destination || !pin) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Payload email PIN rujukan belum lengkap.');
  }

  if (!isValidEmail(email)) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Alamat email pasien tidak valid.');
  }

  if (!/^\d{6}$/.test(pin)) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'PIN rujukan harus terdiri dari 6 digit.');
  }

  const referralUrl = new URL(`/rujukan/${referralId}`, portalBaseUrl).toString();
  const expiresAt = new Date(referral.expires_at);
  if (Number.isNaN(expiresAt.getTime())) {
    throw new MailFlowError(400, 'BAD_REQUEST', 'Tanggal kedaluwarsa referral tidak valid.');
  }

  const renderedEmail = renderReferralPinEmailTemplate({
    patientName,
    destination,
    pin,
    referralUrl,
    expiresText: expiresAt.toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' }),
  });

  await dispatchMail({
    requestId,
    to: email,
    subject: renderedEmail.subject,
    html: renderedEmail.html,
  });
}
