import { requireAdminRole } from '../_shared/auth.ts';
import { checkRateLimit, getClientIp } from '../_shared/rate_limit.ts';
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
    const ipLimit = await checkRateLimit(auth.supabase, `ip:${ip}`, 'admin-update-clinic', 10, 20);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const actorLimit = await checkRateLimit(auth.supabase, `actor:${auth.userId}`, 'admin-update-clinic', 10, 15);
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

    const clinicName = nullableText(body?.clinic_name);
    const clinicSlug = nullableText(body?.clinic_slug);
    const permitNumber = nullableText(body?.permit_number);
    const ownerKtpNumber = nullableText(body?.owner_ktp_number);
    const phoneNumber = nullableText(body?.phone_number);
    const addressLine = nullableText(body?.address_line);
    const rtRw = nullableText(body?.rt_rw);
    const provinceName = nullableText(body?.province_name);
    const cityName = nullableText(body?.city_name);
    const districtName = nullableText(body?.district_name);
    const subdistrictName = nullableText(body?.subdistrict_name);
    const postalCode = nullableText(body?.postal_code);

    if (!clinicName && !clinicSlug && !permitNumber && !ownerKtpNumber && !phoneNumber && !addressLine) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'At least one field must be provided to update.', request_id: requestId,
      });
    }

    const setClauses: string[] = [];
    const params: Record<string, unknown> = { p_clinic_id: clinicId };

    if (clinicName) { setClauses.push('name = $2'); params.p_name = clinicName; }
    if (clinicSlug) { setClauses.push('slug = $3'); params.p_slug = clinicSlug; }
    if (permitNumber) { setClauses.push('permit_number = $4'); params.p_permit_number = permitNumber; }
    if (ownerKtpNumber) { setClauses.push('owner_ktp_number = $5'); params.p_owner_ktp_number = ownerKtpNumber; }
    if (phoneNumber) { setClauses.push('phone_number = $6'); params.p_phone_number = phoneNumber; }
    if (addressLine) { setClauses.push('address_line = $7'); params.p_address_line = addressLine; }
    if (rtRw) { setClauses.push('rt_rw = $8'); params.p_rt_rw = rtRw; }
    if (provinceName) { setClauses.push('province_name = $9'); params.p_province_name = provinceName; }
    if (cityName) { setClauses.push('city_name = $10'); params.p_city_name = cityName; }
    if (districtName) { setClauses.push('district_name = $11'); params.p_district_name = districtName; }
    if (subdistrictName) { setClauses.push('subdistrict_name = $12'); params.p_subdistrict_name = subdistrictName; }
    if (postalCode) { setClauses.push('postal_code = $13'); params.p_postal_code = postalCode; }

    setClauses.push('updated_at = now()');

    const updateSql = `UPDATE public.clinics SET ${setClauses.join(', ')} WHERE id = $1 RETURNING id`;
    const orderedParams = [clinicId];
    const paramKeys = ['p_name', 'p_slug', 'p_permit_number', 'p_owner_ktp_number', 'p_phone_number', 'p_address_line', 'p_rt_rw', 'p_province_name', 'p_city_name', 'p_district_name', 'p_subdistrict_name', 'p_postal_code'];
    for (const key of paramKeys) {
      if (params[key] !== undefined) orderedParams.push(params[key]);
    }

    const { data: updateResult, error: updateError } = await auth.supabase.from('clinics').update({
      ...(clinicName && { name: clinicName }),
      ...(clinicSlug && { slug: clinicSlug }),
      ...(permitNumber && { permit_number: permitNumber }),
      ...(ownerKtpNumber && { owner_ktp_number: ownerKtpNumber }),
      ...(phoneNumber && { phone_number: phoneNumber }),
      ...(addressLine && { address_line: addressLine }),
      ...(rtRw && { rt_rw: rtRw }),
      ...(provinceName && { province_name: provinceName }),
      ...(cityName && { city_name: cityName }),
      ...(districtName && { district_name: districtName }),
      ...(subdistrictName && { subdistrict_name: subdistrictName }),
      ...(postalCode && { postal_code: postalCode }),
      updated_at: new Date().toISOString(),
    }).eq('id', clinicId).select('id').single();

    if (updateError || !updateResult) {
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'UPDATE_FAILED', message: 'Failed to update clinic.', request_id: requestId,
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: 'Clinic updated successfully.', request_id: requestId,
      data: { clinic_id: clinicId },
    });
  } catch (error) {
    console.error('[admin-update-clinic]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
