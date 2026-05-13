import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { hashOtpCode } from '../_shared/otp.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);

  try {
    const { email, otp } = await req.json();
    if (!email || !otp) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Mohon lengkapi email dan kode verifikasi.',
      });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const supabase = createServiceRoleClient();

    const ipLimit = await checkRateLimit({
      supabase,
      functionName: 'verify-otp',
      identifier: `ip:${clientIp}`,
      windowSeconds: 60 * 10,
      limit: 20,
    });
    if (!ipLimit.allowed) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Percobaan verifikasi terlalu sering. Silakan tunggu beberapa menit lalu coba kembali.',
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const emailLimit = await checkRateLimit({
      supabase,
      functionName: 'verify-otp',
      identifier: `email:${normalizedEmail}`,
      windowSeconds: 60 * 10,
      limit: 5,
    });
    if (!emailLimit.allowed) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Percobaan verifikasi untuk email ini sudah mencapai batas. Silakan tunggu beberapa menit.',
        data: { retry_after_seconds: emailLimit.retryAfterSeconds },
      });
    }

    const otpHash = await hashOtpCode(String(otp).trim());
    const { data, error } = await supabase
      .from('otp_verifications')
      .select('id, otp_code')
      .eq('email', normalizedEmail)
      .eq('is_verified', false)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(10);

    if (error || !Array.isArray(data) || data.length === 0) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Kode verifikasi tidak valid atau sudah kedaluwarsa. Silakan minta kode baru.',
      });
    }

    const matchedVerification = data.find((row) => {
      const storedOtp = String(row.otp_code ?? '').trim();
      return storedOtp === otpHash || storedOtp === String(otp).trim();
    });

    if (!matchedVerification?.id) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Kode verifikasi tidak valid atau sudah kedaluwarsa. Silakan minta kode baru.',
      });
    }

    const { error: updateError } = await supabase
      .from('otp_verifications')
      .update({ is_verified: true })
      .eq('id', matchedVerification.id);

    if (updateError) {
      console.error('[verify-otp]', requestId, 'updateError', updateError);
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.',
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Kode verifikasi berhasil dikonfirmasi.',
      data: { verification_id: matchedVerification.id, email: normalizedEmail },
    });
  } catch (err) {
    console.error('[verify-otp]', requestId, 'unexpectedError', err);
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
