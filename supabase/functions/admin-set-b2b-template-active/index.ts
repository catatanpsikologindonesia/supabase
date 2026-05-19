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
    const ipLimit = await checkRateLimit(auth.supabase, `ip:${ip}`, 'admin-set-b2b-template-active', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(auth.supabase, `actor:${auth.userId}`, 'admin-set-b2b-template-active', 10, 15);
    if (actorLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: actorLimit.retryAfterSeconds },
      });
    }

    const body = await req.json();
    const templateId = asString(body?.template_id);
    if (!isValidUuid(templateId)) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'template_id is required and must be a valid UUID.', request_id: requestId,
      });
    }

    const isActive = asBool(body?.is_active);

    const { data: template, error: fetchError } = await auth.supabase
      .from('b2b_agreement_templates')
      .select('id')
      .eq('id', templateId)
      .single();

    if (fetchError || !template) {
      return respond(404, requestId, allowedOrigin, {
        success: false, code: 'NOT_FOUND', message: 'B2B agreement template not found.', request_id: requestId,
      });
    }

    if (isActive) {
      const { error: deactivateAllError } = await auth.supabase
        .from('b2b_agreement_templates')
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .neq('is_active', false);

      if (deactivateAllError) {
        return respond(500, requestId, allowedOrigin, {
          success: false, code: 'DEACTIVATE_FAILED', message: 'Failed to deactivate existing templates.', request_id: requestId,
        });
      }
    }

    const { error: updateError } = await auth.supabase
      .from('b2b_agreement_templates')
      .update({ is_active: isActive, updated_at: new Date().toISOString() })
      .eq('id', templateId);

    if (updateError) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'UPDATE_FAILED', message: 'Failed to update template active status.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: `Template ${isActive ? 'activated' : 'deactivated'} successfully.`, request_id: requestId,
      data: { template_id: templateId, is_active: isActive },
    });
  } catch (error) {
    console.error('[admin-set-b2b-template-active]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
