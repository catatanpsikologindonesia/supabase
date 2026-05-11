import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';
import { asString, isValidUuid } from '../_shared/validation.ts';
import {
  generateRequestId,
  preflight,
  resolveAllowedOrigin,
  secureHeaders,
} from '../_shared/http.ts';

type EdgeResponseBody = {
  success: boolean;
  code: string;
  message: string;
  request_id: string;
  data?: unknown;
};

function respond(
  status: number,
  requestId: string,
  allowedOrigin: string | null,
  body: EdgeResponseBody,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...secureHeaders(allowedOrigin),
      'Content-Type': 'application/json',
      'x-request-id': requestId,
    },
  });
}

function createCallerClient(authHeader: string) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const supabaseAnonKey =
    Deno.env.get('SUPABASE_ANON_KEY')?.trim() ||
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY')?.trim() ||
    '';
  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY for edge function caller client.');
  }
  return createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      headers: {
        Authorization: authHeader,
        apikey: supabaseAnonKey,
      },
    },
  });
}

Deno.serve(async (req) => {
  const preflightResponse = preflight(req);
  if (preflightResponse) return preflightResponse;

  const requestId = generateRequestId();
  const allowedOrigin = resolveAllowedOrigin(req);

  if (req.method !== 'POST') {
    return respond(405, requestId, allowedOrigin, {
      success: false, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.', request_id: requestId,
    });
  }

  const authHeader = req.headers.get('Authorization')?.trim() ?? '';
  if (!authHeader) {
    return respond(401, requestId, allowedOrigin, {
      success: false, code: 'UNAUTHORIZED', message: 'Authorization header is required.', request_id: requestId,
    });
  }

  try {
    const caller = createCallerClient(authHeader);
    const { data: { user }, error: userError } = await caller.auth.getUser();
    if (userError || !user) {
      return respond(401, requestId, allowedOrigin, {
        success: false, code: 'UNAUTHORIZED', message: 'Unauthorized.', request_id: requestId,
      });
    }

    const { data: isAdmin } = await caller.rpc('is_admin_at_least', { p_min_role: 'STAFF' });
    if (!isAdmin) {
      return respond(403, requestId, allowedOrigin, {
        success: false, code: 'FORBIDDEN', message: 'Caller is not an LBSD admin.', request_id: requestId,
      });
    }

    const service = createServiceRoleClient();
    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'extend-clinic-expiry', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(service, `actor:${user.id}`, 'extend-clinic-expiry', 10, 15);
    if (actorLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: actorLimit.retryAfterSeconds },
      });
    }

    const body = await req.json();
    const clinicId = asString(body?.clinic_id);
    if (!isValidUuid(clinicId)) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'clinic_id is required and must be a valid UUID.', request_id: requestId,
      });
    }

    const extensionDays = typeof body?.extension_days === 'number' && body.extension_days > 0
      ? Math.min(Math.floor(body.extension_days), 365)
      : 30;

    const { data: clinic, error: fetchError } = await service
      .from('clinics')
      .select('id, expired_date')
      .eq('id', clinicId)
      .single();

    if (fetchError || !clinic) {
      return respond(404, requestId, allowedOrigin, {
        success: false, code: 'NOT_FOUND', message: 'Clinic not found.', request_id: requestId,
      });
    }

    const currentExpiry = clinic.expired_date ? new Date(clinic.expired_date) : new Date();
    if (!clinic.expired_date || currentExpiry < new Date()) {
      currentExpiry.setTime(Date.now());
    }
    const newExpiry = new Date(currentExpiry.getTime() + extensionDays * 24 * 60 * 60 * 1000).toISOString();

    const { error: updateError } = await service
      .from('clinics')
      .update({ expired_date: newExpiry, updated_at: new Date().toISOString() })
      .eq('id', clinicId);

    if (updateError) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'EXTEND_FAILED', message: 'Failed to extend clinic expiry.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: `Clinic expiry extended by ${extensionDays} days.`, request_id: requestId,
      data: { clinic_id: clinicId, new_expired_date: newExpiry, extension_days: extensionDays },
    });
  } catch (error) {
    console.error('[extend-clinic-expiry]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
