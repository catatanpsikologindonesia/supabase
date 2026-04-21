import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';

type AcceptConsentPayload = {
  token?: unknown;
  agreeToDataSharing?: unknown;
};

type ConsentRpcResponse = {
  status: 'success' | 'error';
  code?: string;
  message?: string;
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

function getRequestIp(req: Request) {
  return req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? req.headers.get('x-real-ip')?.trim() ?? null;
}

function getStatusCodeFromConsentCode(code?: string) {
  switch (code) {
    case 'INVALID_TOKEN':
    case 'INVALID_FLOW':
    case 'INVITATION_CLINIC_REQUIRED':
      return 400;
    case 'INVITATION_NOT_FOUND':
    case 'PATIENT_NOT_FOUND':
      return 404;
    case 'INVITATION_USED':
    case 'INVITATION_SUPERSEDED':
      return 409;
    case 'INVITATION_EXPIRED':
      return 410;
    case 'NO_PRACTITIONER':
      return 400;
    default:
      return 500;
  }
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
    const payload = (await req.json()) as AcceptConsentPayload;
    const token = asTrimmedString(payload.token);
    const agreeToDataSharing = payload.agreeToDataSharing === true;

    if (!token || !agreeToDataSharing) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Data persetujuan tidak valid.',
      });
    }

    const supabase = createPublicClient(req);
    const consentIp = getRequestIp(req);
    const consentUserAgent = req.headers.get('user-agent') ?? null;

    const { data, error } = await supabase.rpc('accept_patient_consent_by_token', {
      invite_token: token,
      consent_ip: consentIp,
      consent_user_agent: consentUserAgent,
    });

    if (error) {
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: `Gagal memproses persetujuan: ${error.message}`,
      });
    }

    const result = (data ?? null) as ConsentRpcResponse | null;
    if (!result) {
      return jsonResponse({
        req,
        requestId,
        status: 500,
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Gagal memproses persetujuan karena response server kosong.',
      });
    }

    if (result.status === 'error') {
      return jsonResponse({
        req,
        requestId,
        status: getStatusCodeFromConsentCode(result.code),
        success: false,
        code: 'BAD_REQUEST',
        message: result.message ?? 'Gagal memproses persetujuan.',
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: result.message ?? 'Persetujuan data berhasil diproses.',
    });
  } catch (error) {
    console.error('[accept-patient-consent]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Terjadi kesalahan saat memproses persetujuan data.',
    });
  }
});
