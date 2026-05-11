import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';
import { asString, isValidEmail, isValidUuid, nullableText } from '../_shared/validation.ts';
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

async function sha256Hex(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
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
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'create-b2b-invitation', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(service, `actor:${user.id}`, 'create-b2b-invitation', 10, 15);
    if (actorLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: actorLimit.retryAfterSeconds },
      });
    }

    const body = await req.json();
    const clinicId = asString(body?.clinic_id);
    const templateId = asString(body?.template_id);
    const signerName = asString(body?.signer_name);
    const signerEmail = asString(body?.signer_email);
    const signerPosition = nullableText(body?.signer_position);
    const expiresInDays = typeof body?.expires_in_days === 'number' ? body.expires_in_days : 14;

    if (!isValidUuid(clinicId)) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'clinic_id is required and must be a valid UUID.', request_id: requestId,
      });
    }

    if (!isValidUuid(templateId)) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'template_id is required and must be a valid UUID.', request_id: requestId,
      });
    }

    if (!signerName) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'signer_name is required.', request_id: requestId,
      });
    }

    if (!isValidEmail(signerEmail)) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_EMAIL', message: 'signer_email is invalid.', request_id: requestId,
      });
    }

    const uuidToken = crypto.randomUUID();
    const tokenHash = await sha256Hex(uuidToken);
    const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000).toISOString();

    const { data: invitation, error: insertError } = await service
      .from('b2b_invitations')
      .insert({
        clinic_id: clinicId,
        template_id: templateId,
        token_hash: tokenHash,
        signer_name: signerName,
        signer_email: signerEmail,
        signer_position: signerPosition,
        status: 'pending',
        expires_at: expiresAt,
      })
      .select('id')
      .single();

    if (insertError || !invitation) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'CREATE_FAILED', message: 'Failed to create B2B invitation.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: 'B2B invitation created successfully.', request_id: requestId,
      data: {
        invitation_id: invitation.id,
        token: uuidToken,
        signing_url: `/b2b-agreement?token=${uuidToken}`,
        expires_at: expiresAt,
      },
    });
  } catch (error) {
    console.error('[create-b2b-invitation]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
