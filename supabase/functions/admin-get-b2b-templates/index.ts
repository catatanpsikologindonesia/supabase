import { requireAdminRole } from '../_shared/auth.ts';
import { checkRateLimit, getClientIp } from '../_shared/rate_limit.ts';
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

  if (req.method !== 'GET' && req.method !== 'POST') {
    return respond(405, requestId, allowedOrigin, {
      success: false, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.', request_id: requestId,
    });
  }

  try {
    const auth = await requireAdminRole(req);
    if (!auth.ok) return auth.response;

    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(auth.supabase, `ip:${ip}`, 'admin-get-b2b-templates', 10, 40);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const { data: templates, error: fetchError } = await auth.supabase
      .from('b2b_agreement_templates')
      .select('*')
      .order('created_at', { ascending: false });

    if (fetchError) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'FETCH_FAILED', message: 'Failed to fetch B2B agreement templates.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: 'Templates fetched successfully.', request_id: requestId,
      data: { templates: templates ?? [] },
    });
  } catch (error) {
    console.error('[admin-get-b2b-templates]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
