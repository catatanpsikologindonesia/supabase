import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';
import { getPasswordCriteria, isPasswordPolicyValid } from '../_shared/password_policy.ts';
import { asString, isValidEmail, nullableText } from '../_shared/validation.ts';
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

type CreateClinicRpcResult = {
  status?: 'success' | 'error';
  message?: string;
  clinicId?: string;
  membershipId?: string;
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
      success: false,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Method not allowed.',
      request_id: requestId,
    });
  }

  const authHeader = req.headers.get('Authorization')?.trim() ?? '';
  if (!authHeader) {
    return respond(401, requestId, allowedOrigin, {
      success: false,
      code: 'UNAUTHORIZED',
      message: 'Authorization header is required.',
      request_id: requestId,
    });
  }

  try {
    const caller = createCallerClient(authHeader);
    const {
      data: { user },
      error: userError,
    } = await caller.auth.getUser();

    if (userError || !user) {
      return respond(401, requestId, allowedOrigin, {
        success: false,
        code: 'UNAUTHORIZED',
        message: 'Unauthorized.',
        request_id: requestId,
      });
    }

    const { data: isAdmin, error: adminError } = await caller.rpc('is_admin_at_least', {
      p_min_role: 'STAFF',
    });

    if (adminError || !isAdmin) {
      return respond(403, requestId, allowedOrigin, {
        success: false,
        code: 'FORBIDDEN',
        message: 'Caller is not an LBSD admin.',
        request_id: requestId,
      });
    }

    const service = createServiceRoleClient();
    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'admin-create-clinic', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false,
        code: 'RATE_LIMITED',
        message: 'Too many requests.',
        request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(service, `actor:${user.id}`, 'admin-create-clinic', 10, 15);
    if (actorLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false,
        code: 'RATE_LIMITED',
        message: 'Too many requests.',
        request_id: requestId,
        data: { retry_after_seconds: actorLimit.retryAfterSeconds },
      });
    }

    const body = await req.json();
    const clinicName = asString(body?.clinic_name);
    const clinicSlug = nullableText(body?.clinic_slug);
    const ownerEmail = asString(body?.owner_email).toLowerCase();
    const ownerPassword = asString(body?.owner_password);
    const ownerFullName = asString(body?.owner_full_name);

    if (!clinicName) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_INPUT',
        message: 'clinic_name is required.',
        request_id: requestId,
        data: { field: 'clinic_name' },
      });
    }

    if (!isValidEmail(ownerEmail)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_EMAIL',
        message: 'Owner email is invalid.',
        request_id: requestId,
      });
    }

    if (!isPasswordPolicyValid(ownerPassword)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'WEAK_PASSWORD',
        message: 'Password does not meet the required policy.',
        request_id: requestId,
        data: getPasswordCriteria(),
      });
    }

    if (!ownerFullName) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_INPUT',
        message: 'owner_full_name is required.',
        request_id: requestId,
        data: { field: 'owner_full_name' },
      });
    }

    const { data: authData, error: authError } = await service.auth.admin.createUser({
      email: ownerEmail,
      password: ownerPassword,
      email_confirm: true,
      user_metadata: { full_name: ownerFullName },
    });

    if (authError || !authData.user) {
      const normalizedMessage = authError?.message.toLowerCase() ?? '';
      if (normalizedMessage.includes('already') || normalizedMessage.includes('registered')) {
        return respond(400, requestId, allowedOrigin, {
          success: false,
          code: 'EMAIL_TAKEN',
          message: 'Email already registered.',
          request_id: requestId,
        });
      }

      return respond(500, requestId, allowedOrigin, {
        success: false,
        code: 'AUTH_CREATE_FAILED',
        message: 'Failed to create auth user.',
        request_id: requestId,
      });
    }

    const newUserId = authData.user.id;
    const { data: rpcResult, error: rpcError } = await caller.rpc('create_clinic_with_owner', {
      clinic_name: clinicName,
      clinic_slug: clinicSlug,
      owner_user_id: newUserId,
    });

    const rpcPayload = (rpcResult ?? null) as CreateClinicRpcResult | null;
    if (rpcError || rpcPayload?.status === 'error') {
      await service.auth.admin.deleteUser(newUserId);

      return respond(500, requestId, allowedOrigin, {
        success: false,
        code: 'CLINIC_CREATE_FAILED',
        message: rpcPayload?.message ?? rpcError?.message ?? 'Failed to create clinic.',
        request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true,
      code: 'OK',
      message: 'Clinic created successfully.',
      request_id: requestId,
      data: {
        clinic_id: rpcPayload?.clinicId ?? null,
        owner_membership_id: rpcPayload?.membershipId ?? null,
        user_id: newUserId,
      },
    });
  } catch (error) {
    console.error('[admin-create-clinic]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Internal server error.',
      request_id: requestId,
    });
  }
});
