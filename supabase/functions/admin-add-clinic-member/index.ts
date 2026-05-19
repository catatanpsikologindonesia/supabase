import { requireAdminRole } from '../_shared/auth.ts';
import { checkRateLimit, getClientIp } from '../_shared/rate_limit.ts';
import { getPasswordCriteria, isPasswordPolicyValid } from '../_shared/password_policy.ts';
import {
  asBool,
  asString,
  isValidEmail,
  isValidProfession,
  isValidUuid,
  nullableText,
} from '../_shared/validation.ts';
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

type AddMemberRpcResult = {
  status?: 'success' | 'error';
  code?: string;
  message?: string;
  membershipId?: string;
  userId?: string;
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
      success: false,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Method not allowed.',
      request_id: requestId,
    });
  }

  try {
    const auth = await requireAdminRole(req);
    if (!auth.ok) return auth.response;

    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(auth.supabase, `ip:${ip}`, 'admin-add-clinic-member', 10, 40);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false,
        code: 'RATE_LIMITED',
        message: 'Too many requests.',
        request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(auth.supabase, `actor:${auth.userId}`, 'admin-add-clinic-member', 10, 30);
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
    const clinicId = asString(body?.clinic_id);
    const memberEmail = asString(body?.member_email).toLowerCase();
    const memberPassword = asString(body?.member_password);
    const fullName = asString(body?.full_name);
    const isStaff = asBool(body?.is_staff);
    const isPractitioner = asBool(body?.is_practitioner);
    const profession = nullableText(body?.profession);

    if (!isValidUuid(clinicId)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_CLINIC_ID',
        message: 'clinic_id must be a valid UUID.',
        request_id: requestId,
      });
    }

    if (!isValidEmail(memberEmail)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_EMAIL',
        message: 'Member email is invalid.',
        request_id: requestId,
      });
    }

    if (!isPasswordPolicyValid(memberPassword)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'WEAK_PASSWORD',
        message: 'Password does not meet the required policy.',
        request_id: requestId,
        data: getPasswordCriteria(),
      });
    }

    if (!fullName) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_INPUT',
        message: 'full_name is required.',
        request_id: requestId,
        data: { field: 'full_name' },
      });
    }

    if (isPractitioner && profession && !isValidProfession(profession)) {
      return respond(400, requestId, allowedOrigin, {
        success: false,
        code: 'INVALID_PROFESSION',
        message: 'Profession is invalid.',
        request_id: requestId,
      });
    }

    const { data: authData, error: authError } = await auth.supabase.auth.admin.createUser({
      email: memberEmail,
      password: memberPassword,
      email_confirm: true,
      user_metadata: { full_name: fullName },
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
    const { data: rpcResult, error: rpcError } = await auth.caller.rpc('admin_add_clinic_member', {
      p_clinic_id: clinicId,
      p_user_id: newUserId,
      p_full_name: fullName,
      p_email: memberEmail,
      p_is_staff: isStaff,
      p_is_practitioner: isPractitioner,
      p_profession: isPractitioner ? profession ?? 'psychologist' : null,
    });

    const rpcPayload = (rpcResult ?? null) as AddMemberRpcResult | null;
    if (rpcError || rpcPayload?.status === 'error') {
      await auth.supabase.auth.admin.deleteUser(newUserId);
      const code = rpcPayload?.code ?? 'MEMBER_ADD_FAILED';

      return respond(code === 'CLINIC_NOT_FOUND' ? 400 : 500, requestId, allowedOrigin, {
        success: false,
        code,
        message: rpcPayload?.message ?? rpcError?.message ?? 'Failed to add clinic member.',
        request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true,
      code: 'OK',
      message: 'Clinic member added successfully.',
      request_id: requestId,
      data: {
        membership_id: rpcPayload?.membershipId ?? null,
        user_id: newUserId,
      },
    });
  } catch (error) {
    console.error('[admin-add-clinic-member]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Internal server error.',
      request_id: requestId,
    });
  }
});
