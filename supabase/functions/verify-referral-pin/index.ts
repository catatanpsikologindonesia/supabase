import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';

type VerifyReferralPinPayload = {
  referralId?: unknown;
  pin?: unknown;
};

type VerifyReferralRpcResponse = {
  status: 'success' | 'error';
  code?: string;
  message?: string;
  data?: {
    id: string;
    destination: string;
    notes: string;
    createdAt: string;
    expiresAt: string;
    clinicName?: string | null;
    patientName?: string | null;
    psychologistName?: string | null;
    psychologistEmail?: string | null;
    psychologistSipNumber?: string | null;
    psychologistProfession?: 'psychologist' | 'counselor' | 'other' | null;
  };
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function resolvePublicAnonKey(req: Request): string {
  const headerKey = req.headers.get('apikey')?.trim() ?? '';
  const envCandidates = [
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ?? '',
  ].map((value) => value.trim());

  for (const key of [headerKey, ...envCandidates]) {
    if (!key) continue;
    return key;
  }

  throw new Error('Missing anon/publishable key for public edge client.');
}

function createPublicClient(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  if (!supabaseUrl) {
    throw new Error('SUPABASE_URL is not configured.');
  }

  return createClient(supabaseUrl, resolvePublicAnonKey(req), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function getStatusCodeFromVerifyCode(code?: string) {
  switch (code) {
    case 'INVALID_INPUT':
      return 400;
    case 'REFERRAL_NOT_FOUND':
      return 404;
    case 'REFERRAL_EXPIRED':
      return 410;
    case 'INVALID_PIN':
      return 401;
    default:
      return 500;
  }
}

function normalizePayload(data?: VerifyReferralRpcResponse['data']) {
  if (!data) return null;

  return {
    ...data,
    clinicName: data.clinicName ?? 'Catatan Psikolog',
    patientName: data.patientName ?? 'Pasien',
    psychologistName: data.psychologistName ?? 'Tim Psikolog',
    psychologistEmail: data.psychologistEmail ?? null,
    psychologistSipNumber: data.psychologistSipNumber ?? null,
    psychologistProfession: data.psychologistProfession ?? null,
  };
}

Deno.serve(async (req) => {
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
    const payload = (await req.json()) as VerifyReferralPinPayload;
    const referralId = asTrimmedString(payload.referralId);
    const pin = asTrimmedString(payload.pin);

    if (!referralId || !/^[0-9a-fA-F-]{36}$/.test(referralId) || !/^\d{6}$/.test(pin)) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'INVALID_INPUT',
        message: 'Input tidak valid.',
      });
    }

    const supabase = createPublicClient(req);
    const { data, error } = await supabase.rpc('verify_referral_pin', {
      referral_id: referralId,
      input_pin: pin,
    });

    if (error) {
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: `Gagal memverifikasi PIN: ${error.message}`,
      });
    }

    const result = (data ?? null) as VerifyReferralRpcResponse | null;
    if (!result) {
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Verifikasi gagal karena response server kosong.',
      });
    }

    if (result.status === 'error') {
      return jsonResponse({
        req,
        requestId,
        status: getStatusCodeFromVerifyCode(result.code),
        success: false,
        code: (result.code as 'INVALID_INPUT' | 'REFERRAL_NOT_FOUND' | 'REFERRAL_EXPIRED' | 'INVALID_PIN' | undefined) ?? 'INTERNAL_ERROR',
        message: result.message ?? 'PIN tidak valid.',
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: result.message ?? 'PIN valid. Dokumen berhasil dibuka.',
      data: normalizePayload(result.data),
    });
  } catch (error) {
    console.error('[verify-referral-pin]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Terjadi kesalahan saat memverifikasi PIN.',
    });
  }
});
