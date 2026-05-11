import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';
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

  if (req.method !== 'GET' && req.method !== 'POST') {
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
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'admin-get-b2b-templates', 10, 40);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const { data: templates, error: fetchError } = await service
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
