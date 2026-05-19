import { requireAdminRole } from '../_shared/auth.ts';
import { checkRateLimit, getClientIp } from '../_shared/rate_limit.ts';
import { asBool, isValidUuid } from '../_shared/validation.ts';
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

  try {
    const auth = await requireAdminRole(req);
    if (!auth.ok) return auth.response;

    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(auth.supabase, `ip:${ip}`, 'admin-toggle-clinic-active', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(auth.supabase, `actor:${auth.userId}`, 'admin-toggle-clinic-active', 10, 15);
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

    const { data: clinic, error: fetchError } = await auth.supabase
      .from('clinics')
      .select('id, is_active')
      .eq('id', clinicId)
      .single();

    if (fetchError || !clinic) {
      return respond(404, requestId, allowedOrigin, {
        success: false, code: 'NOT_FOUND', message: 'Clinic not found.', request_id: requestId,
      });
    }

    const newActive = !clinic.is_active;
    const { error: updateError } = await auth.supabase
      .from('clinics')
      .update({ is_active: newActive, updated_at: new Date().toISOString() })
      .eq('id', clinicId);

    if (updateError) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'TOGGLE_FAILED', message: 'Failed to toggle clinic active status.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: `Clinic ${newActive ? 'activated' : 'deactivated'} successfully.`, request_id: requestId,
      data: { clinic_id: clinicId, is_active: newActive },
    });
  } catch (error) {
    console.error('[admin-toggle-clinic-active]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
