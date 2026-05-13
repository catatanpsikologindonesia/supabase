import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';
import { isPasswordPolicyValid } from '../_shared/password_policy.ts';

const PASSWORD_POLICY_MESSAGE_ID = 'Kata sandi minimal 6 karakter dan harus mengandung huruf besar, huruf kecil, angka, serta simbol.';

async function findAuthUserIdFromProfiles(
  supabase: ReturnType<typeof createServiceRoleClient>,
  normalizedEmail: string,
): Promise<{ ok: true; userId: string | null } | { ok: false }> {
  const { data, error } = await supabase
    .from('clinic_memberships')
    .select('user_id')
    .ilike('email', normalizedEmail)
    .limit(1);

  if (error) return { ok: false };
  const row = Array.isArray(data) ? (data[0] as { user_id?: string } | undefined) : undefined;
  return { ok: true, userId: row?.user_id ?? null };
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);

  try {
    const { verification_id, new_password } = await req.json();
    if (!verification_id || !new_password) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Sesi verifikasi dan kata sandi baru wajib diisi.',
      });
    }

    if (!isPasswordPolicyValid(String(new_password))) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: PASSWORD_POLICY_MESSAGE_ID,
      });
    }

    const supabase = createServiceRoleClient();

    const ipLimit = await checkRateLimit({
      supabase,
      functionName: 'reset-password',
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
        message: 'Percobaan terlalu sering. Silakan tunggu beberapa menit lalu coba kembali.',
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const verificationLimit = await checkRateLimit({
      supabase,
      functionName: 'reset-password',
      identifier: `verification:${verification_id}`,
      windowSeconds: 60 * 10,
      limit: 3,
    });
    if (!verificationLimit.allowed) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Percobaan untuk sesi ini sudah mencapai batas. Silakan minta kode verifikasi baru.',
        data: { retry_after_seconds: verificationLimit.retryAfterSeconds },
      });
    }

    const { data: otpData, error: otpError } = await supabase
      .from('otp_verifications')
      .select('email, id, expires_at')
      .eq('id', verification_id)
      .eq('is_verified', true)
      .gt('expires_at', new Date().toISOString())
      .single();

    if (otpError || !otpData) {
      return jsonResponse({
        req,
        requestId,
        status: 401,
        success: false,
        code: 'UNAUTHORIZED',
        message: 'Sesi reset tidak valid atau sudah kedaluwarsa. Silakan minta kode verifikasi baru.',
      });
    }

    const userLookup = await findAuthUserIdFromProfiles(supabase, String(otpData.email ?? '').trim().toLowerCase());
    if (!userLookup.ok) {
      console.error('[reset-password]', requestId, 'profileLookupError');
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Layanan sedang mengalami kendala. Silakan coba beberapa saat lagi.',
      });
    }

    if (!userLookup.userId) {
      return jsonResponse({
        req,
        requestId,
        status: 401,
        success: false,
        code: 'UNAUTHORIZED',
        message: 'Sesi reset tidak valid atau sudah kedaluwarsa. Silakan minta kode verifikasi baru.',
      });
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(userLookup.userId, {
      password: new_password,
    });

    if (updateError) {
      console.error('[reset-password]', requestId, 'updateError', updateError);
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Kata sandi belum berhasil diperbarui. Silakan coba kembali.',
      });
    }

    await supabase.from('otp_verifications').delete().eq('id', verification_id);

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Kata sandi berhasil diperbarui.',
    });
  } catch (err) {
    console.error('[reset-password]', requestId, 'unexpectedError', err);
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
