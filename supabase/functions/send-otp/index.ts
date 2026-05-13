import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';
import { generateOtpCode, hashOtpCode } from '../_shared/otp.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';

async function isRegisteredProfileEmail(
  supabase: ReturnType<typeof createServiceRoleClient>,
  normalizedEmail: string,
): Promise<{ ok: true; exists: boolean } | { ok: false }> {
  const { data, error } = await supabase.rpc('is_registered_profile_email', {
    p_email: normalizedEmail,
  });
  if (error) return { ok: false };
  return { ok: true, exists: data === true };
}

function renderSendOtpEmailTemplate(otpCode: string) {
  return {
    subject: 'Kode OTP Pemulihan Akun Catatan Psikolog',
    html: `
      <div style="font-family: Arial, sans-serif; color: #2f2f3a; line-height: 1.6;">
        <h2 style="margin-bottom: 12px;">Pemulihan Akun Catatan Psikolog</h2>
        <p>Gunakan kode OTP berikut untuk melanjutkan proses pemulihan kata sandi Anda:</p>
        <div style="margin: 24px 0; font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #6f56d9;">${otpCode}</div>
        <p>Kode ini berlaku selama 30 menit. Jika Anda tidak meminta reset kata sandi, abaikan email ini.</p>
      </div>
    `,
  };
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);
  const genericOtpDispatchMessage = 'Jika email terdaftar, kode verifikasi akan segera dikirim.';

  try {
    const { email } = await req.json();
    if (!email || typeof email !== 'string') {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Mohon isi alamat email terlebih dahulu.',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const supabase = createServiceRoleClient();

    const ipLimit = await checkRateLimit({
      supabase,
      functionName: 'send-otp',
      identifier: `ip:${clientIp}`,
      windowSeconds: 60 * 10,
      limit: 10,
    });

    if (!ipLimit.allowed) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Permintaan terlalu sering. Silakan tunggu beberapa menit lalu coba kembali.',
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const userCheck = await isRegisteredProfileEmail(supabase, normalizedEmail);
    if (!userCheck.ok) {
      console.error('[send-otp]', requestId, 'profileLookupError');
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.',
      });
    }

    if (!userCheck.exists) {
      return jsonResponse({
        req,
        requestId,
        status: 200,
        success: true,
        code: 'OK',
        message: genericOtpDispatchMessage,
        data: { email: normalizedEmail },
      });
    }

    const oneHourAgo = new Date(Date.now() - 60 * 60000).toISOString();
    const { count, error: countError } = await supabase
      .from('otp_verifications')
      .select('*', { count: 'exact', head: true })
      .eq('email', normalizedEmail)
      .gt('created_at', oneHourAgo);

    if (countError) {
      console.error('[send-otp]', requestId, 'countError', countError);
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.',
      });
    }

    if (count !== null && count >= 3) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Permintaan kode verifikasi untuk email ini sudah mencapai batas. Silakan coba kembali nanti.',
      });
    }

    const otp = generateOtpCode();
    const otpHash = await hashOtpCode(otp);
    const expiresAt = new Date(Date.now() + 30 * 60000);

    const { error: insertError } = await supabase
      .from('otp_verifications')
      .insert([{ email: normalizedEmail, otp_code: otpHash, expires_at: expiresAt }]);

    if (insertError) {
      console.error('[send-otp]', requestId, 'insertError', insertError);
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.',
      });
    }

    const renderedEmail = renderSendOtpEmailTemplate(otp);

    try {
      await dispatchMail({
        requestId,
        to: normalizedEmail,
        subject: renderedEmail.subject,
        html: renderedEmail.html,
      });
    } catch (mailErr) {
      console.error('[send-otp]', requestId, 'mailDispatchError', mailErr);
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Kode verifikasi belum berhasil dikirim. Silakan coba kembali.',
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: genericOtpDispatchMessage,
      data: { email: normalizedEmail },
    });
  } catch (err) {
    console.error('[send-otp]', requestId, 'unexpectedError', err);
    return jsonResponse({
      req,
      requestId,
      status: 400,
      success: false,
      code: 'BAD_REQUEST',
      message: 'Data permintaan belum lengkap atau tidak sesuai.',
    });
  }
});
