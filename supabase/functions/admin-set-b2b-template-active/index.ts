import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';
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
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'admin-set-b2b-template-active', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(service, `actor:${user.id}`, 'admin-set-b2b-template-active', 10, 15);
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

    const { data: template, error: fetchError } = await service
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
      const { error: deactivateAllError } = await service
        .from('b2b_agreement_templates')
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .neq('is_active', false);

      if (deactivateAllError) {
        return respond(500, requestId, allowedOrigin, {
          success: false, code: 'DEACTIVATE_FAILED', message: 'Failed to deactivate existing templates.', request_id: requestId,
        });
      }
    }

    const { error: updateError } = await service
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
