import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { requirePortalRole } from '../_shared/auth.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { isMailFlowError } from '../_shared/mail_flow_errors.ts';
import { sendReferralPinMail } from '../_shared/referral_pin_mail.ts';

type ReferralPinPayload = {
  referral_id?: unknown;
  portal_base_url?: unknown;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);

  if (req.method !== 'POST') {
    return jsonResponse({
      req,
      requestId,
      status: 400,
      success: false,
      code: 'BAD_REQUEST',
      message: 'Method tidak didukung.',
    });
  }

  try {
    const auth = await requirePortalRole(req);
    if (!auth.ok) {
      return jsonResponse({
        req,
        requestId,
        status: auth.status,
        success: false,
        code: auth.code,
        message: auth.message,
      });
    }

    const payload = (await req.json()) as ReferralPinPayload;
    const referralId = asTrimmedString(payload.referral_id);
    const portalBaseUrl = asTrimmedString(payload.portal_base_url);
    await sendReferralPinMail({
      supabase: auth.supabase,
      userId: auth.userId,
      requestId,
      referralId,
      portalBaseUrl,
    });

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Email PIN rujukan berhasil dikirim.',
    });
  } catch (error) {
    if (isMailFlowError(error)) {
      return jsonResponse({
        req,
        requestId,
        status: error.status,
        success: false,
        code: error.code,
        message: error.message,
      });
    }
    console.error('[send-referral-pin]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Pengiriman email PIN rujukan gagal.',
    });
  }
});
