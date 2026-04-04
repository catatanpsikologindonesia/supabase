import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { requirePortalRole } from '../_shared/auth.ts';
import { renderRegistrationInviteEmailTemplate } from '../_shared/email_templates/registration_invite.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';

type RegistrationInvitePayload = {
  email?: unknown;
  token?: unknown;
  registration_base_url?: unknown;
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

    const payload = (await req.json()) as RegistrationInvitePayload;
    const email = asTrimmedString(payload.email).toLowerCase();
    const token = asTrimmedString(payload.token);
    const registrationBaseUrl = asTrimmedString(payload.registration_base_url);
    const expiresAtRaw = asTrimmedString(payload.expires_at);

    if (!email || !token || !registrationBaseUrl) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Payload undangan belum lengkap.',
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

    const registrationUrl = new URL(`/register/${token}`, registrationBaseUrl).toString();
    const expiresAt = expiresAtRaw ? new Date(expiresAtRaw) : null;
    const expiresText =
      expiresAt && !Number.isNaN(expiresAt.getTime())
        ? `Link ini berlaku sampai ${expiresAt.toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' })}.`
        : 'Link ini memiliki masa berlaku terbatas.';

    const renderedEmail = renderRegistrationInviteEmailTemplate({
      registrationUrl,
      expiresText,
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
      message: 'Email undangan registrasi berhasil dikirim.',
    });
  } catch (error) {
    console.error('[send-registration-invite]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Pengiriman email undangan registrasi gagal.',
    });
  }
});
