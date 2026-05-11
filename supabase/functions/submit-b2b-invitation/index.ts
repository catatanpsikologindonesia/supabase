import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { generateRequestId, preflight, resolveAllowedOrigin, secureHeaders } from '../_shared/http.ts';
import { checkRateLimit, createServiceRoleClient, getClientIp } from '../_shared/rate_limit.ts';

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

async function sha256Hex(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

function decodeBase64Png(base64Data: string): Uint8Array {
  const raw = base64Data.replace(/^data:image\/png;base64,/, '').replace(/\s/g, '');
  const binary = atob(raw);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
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
    const body = await req.json();
    const token = body?.token?.trim();
    const signatureBase64 = body?.signature_base64?.trim();
    const signedIp = getClientIp(req);
    const signedUserAgent = req.headers.get('user-agent')?.trim() || 'unknown';

    if (!token) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'token is required.', request_id: requestId,
      });
    }

    if (!signatureBase64) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'signature_base64 is required.', request_id: requestId,
      });
    }

    const service = createServiceRoleClient();
    const ip = getClientIp(req);
    const ipLimit = await checkRateLimit(service, `ip:${ip}`, 'submit-b2b-invitation', 10, 10);
    if (ipLimit.limited) {
      return respond(429, requestId, allowedOrigin, {
        success: false, code: 'RATE_LIMITED', message: 'Too many requests.', request_id: requestId,
        data: { retry_after_seconds: ipLimit.retryAfterSeconds },
      });
    }

    const tokenHash = await sha256Hex(token);

    const { data: invitation, error: fetchError } = await service
      .from('b2b_invitations')
      .select('id, clinic_id, status, expires_at')
      .eq('token_hash', tokenHash)
      .single();

    if (fetchError || !invitation) {
      return respond(404, requestId, allowedOrigin, {
        success: false, code: 'NOT_FOUND', message: 'Invitation not found.', request_id: requestId,
      });
    }

    if (invitation.status !== 'pending') {
      return respond(410, requestId, allowedOrigin, {
        success: false, code: 'ALREADY_PROCESSED', message: 'This invitation has already been processed.', request_id: requestId,
      });
    }

    if (new Date(invitation.expires_at) < new Date()) {
      return respond(410, requestId, allowedOrigin, {
        success: false, code: 'EXPIRED', message: 'This invitation has expired.', request_id: requestId,
      });
    }

    let signatureUrl: string | null = null;
    try {
      const pngBytes = decodeBase64Png(signatureBase64);
      const fileName = `b2b-signatures/${invitation.id}_${crypto.randomUUID()}.png`;

      const { data: uploadData, error: uploadError } = await service.storage
        .from('b2b-signatures')
        .upload(fileName, pngBytes, {
          contentType: 'image/png',
          upsert: false,
        });

      if (uploadError) {
        console.error('[submit-b2b-invitation] storage upload error:', uploadError);
        return respond(500, requestId, allowedOrigin, {
          success: false, code: 'UPLOAD_FAILED', message: 'Failed to upload signature.', request_id: requestId,
        });
      }

      const { data: signedUrlData } = await service.storage
        .from('b2b-signatures')
        .createSignedUrl(fileName, 86400);

      signatureUrl = signedUrlData?.signedUrl ?? null;
    } catch (uploadErr) {
      console.error('[submit-b2b-invitation] storage error:', uploadErr);
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'UPLOAD_FAILED', message: 'Failed to process signature upload.', request_id: requestId,
      });
    }

    const now = new Date().toISOString();
    const { error: updateError } = await service
      .from('b2b_invitations')
      .update({
        status: 'signed',
        signed_at: now,
        signature_url: signatureUrl,
        signed_ip: signedIp,
        signed_user_agent: signedUserAgent,
        updated_at: now,
      })
      .eq('id', invitation.id);

    if (updateError) {
      console.error('[submit-b2b-invitation] update error:', updateError);
      return respond(500, requestId, allowedOrigin, {
        success: false, code: 'UPDATE_FAILED', message: 'Failed to update invitation status.', request_id: requestId,
      });
    }

    const { error: clinicUpdateError } = await service
      .from('clinics')
      .update({
        is_agreement_signed: true,
        updated_at: now,
      })
      .eq('id', invitation.clinic_id);

    if (clinicUpdateError) {
      console.error('[submit-b2b-invitation] clinic update error:', clinicUpdateError);
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: 'B2B agreement signed successfully.', request_id: requestId,
      data: { invitation_id: invitation.id, signed_at: now },
    });
  } catch (error) {
    console.error('[submit-b2b-invitation]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
