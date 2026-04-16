import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { requirePortalRole } from '../_shared/auth.ts';
import { renderReferralPinEmailTemplate } from '../_shared/email_templates/referral_pin.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';

type ReferralPinPayload = {
  email?: unknown;
  patient_name?: unknown;
  destination?: unknown;
  pin?: unknown;
  referral_id?: unknown;
  portal_base_url?: unknown;
  expires_at?: unknown;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
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
    const email = asTrimmedString(payload.email).toLowerCase();
    const patientName = asTrimmedString(payload.patient_name);
    const destination = asTrimmedString(payload.destination);
    const pin = asTrimmedString(payload.pin);
    const referralId = asTrimmedString(payload.referral_id);
    const portalBaseUrl = asTrimmedString(payload.portal_base_url);
    const expiresAtRaw = asTrimmedString(payload.expires_at);

    if (!email || !patientName || !destination || !pin || !referralId || !portalBaseUrl || !expiresAtRaw) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload email PIN rujukan belum lengkap.',
      });
    }

    if (!isValidEmail(email)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Alamat email pasien tidak valid.',
      });
    }

    if (!/^\d{6}$/.test(pin)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'PIN rujukan harus terdiri dari 6 digit.',
      });
    }

    const referralUrl = new URL(`/rujukan/${referralId}`, portalBaseUrl).toString();
    const expiresAt = new Date(expiresAtRaw);
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
      expiresText: expiresAt.toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' }),
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
