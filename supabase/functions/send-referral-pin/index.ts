import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { requirePortalRole } from '../_shared/auth.ts';
import { renderReferralPinEmailTemplate } from '../_shared/email_templates/referral_pin.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';

type ReferralPinPayload = {
  referral_id?: unknown;
  portal_base_url?: unknown;
  recipient_timezone?: unknown;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function resolveDisplayTimezone(timezone: string): string {
  const candidate = timezone.trim();
  if (!candidate) return 'Asia/Jakarta';

  try {
    new Intl.DateTimeFormat('id-ID', { timeZone: candidate }).format(new Date());
    return candidate;
  } catch {
    return 'Asia/Jakarta';
  }
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

    const payload = (await req.json()) as ReferralPinPayload;
    const referralId = asTrimmedString(payload.referral_id);
    const portalBaseUrl = asTrimmedString(payload.portal_base_url);
    const recipientTimezone = resolveDisplayTimezone(asTrimmedString(payload.recipient_timezone));

    if (!referralId || !portalBaseUrl) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload email PIN rujukan belum lengkap.',
      });
    }

    const { data: referral, error: referralError } = await auth.supabase
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

    if (referralError || !referral || !referral.practitioner_membership_id) {
      return jsonResponse({
        req,
        requestId,
        status: 404,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Data referral tidak ditemukan.',
      });
    }

    const { data: membership } = await auth.supabase
      .from('clinic_memberships')
      .select('id')
      .eq('id', referral.practitioner_membership_id)
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
        message: 'Referral ini tidak dapat dikirim dari akun ini.',
      });
    }

    const { data: patient } = await auth.supabase
      .from('patients')
      .select('email, full_name')
      .eq('id', referral.patient_id)
      .maybeSingle<{ email: string | null; full_name: string | null }>();

    const email = patient?.email?.trim().toLowerCase() ?? '';
    const patientName = patient?.full_name?.trim() || 'Pasien';
    const destination = referral.destination.trim();
    const pin = referral.secure_pin.trim();
    const referralUrl = new URL(`/rujukan/${referralId}`, portalBaseUrl).toString();
    const expiresAt = new Date(referral.expires_at);

    if (!isValidEmail(email) || !/^\d{6}$/.test(pin)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Data referral tidak valid untuk pengiriman email.',
      });
    }

    if (Number.isNaN(expiresAt.getTime())) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Tanggal kedaluwarsa referral tidak valid.',
      });
    }

    const renderedEmail = renderReferralPinEmailTemplate({
      patientName,
      destination,
      pin,
      referralUrl,
      expiresText: expiresAt.toLocaleString('id-ID', { timeZone: recipientTimezone }),
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
      message: 'Email PIN rujukan berhasil dikirim.',
    });
  } catch (error) {
    console.error('[send-referral-pin]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Pengiriman email PIN rujukan gagal.',
    });
  }
});
