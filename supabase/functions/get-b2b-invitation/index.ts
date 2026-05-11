import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { generateRequestId, preflight, resolveAllowedOrigin, secureHeaders } from '../_shared/http.ts';

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

Deno.serve(async (req) => {
  const preflightResponse = preflight(req);
  if (preflightResponse) return preflightResponse;

  const requestId = generateRequestId();
  const allowedOrigin = resolveAllowedOrigin(req);

  if (req.method !== 'GET') {
    return respond(405, requestId, allowedOrigin, {
      success: false, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.', request_id: requestId,
    });
  }

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get('token');

    if (!token || token.trim().length === 0) {
      return respond(400, requestId, allowedOrigin, {
        success: false, code: 'INVALID_INPUT', message: 'token query parameter is required.', request_id: requestId,
      });
    }

    const tokenHash = await sha256Hex(token.trim());

    const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim() || '';
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY.');
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: invitation, error: fetchError } = await supabase
      .from('b2b_invitations')
      .select(`
        id,
        status,
        expires_at,
        signed_at,
        signer_name,
        signer_email,
        signer_position,
        clinic:clinic_id (id, name, address_line, city_name, permit_number),
        template:template_id (id, title, body, version)
      `)
      .eq('token_hash', tokenHash)
      .maybeSingle();

    if (fetchError || !invitation) {
      return respond(404, requestId, allowedOrigin, {
        success: false, code: 'NOT_FOUND', message: 'Invitation not found.', request_id: requestId,
      });
    }

    if (new Date(invitation.expires_at) < new Date()) {
      return respond(410, requestId, allowedOrigin, {
        success: false, code: 'EXPIRED', message: 'This invitation has expired.', request_id: requestId,
        data: { status: 'expired' },
      });
    }

    if (invitation.status !== 'pending') {
      return respond(410, requestId, allowedOrigin, {
        success: false, code: 'ALREADY_SIGNED', message: 'This invitation has already been processed.', request_id: requestId,
        data: { status: invitation.status, signed_at: invitation.signed_at },
      });
    }

    return respond(200, requestId, allowedOrigin, {
      success: true, code: 'OK', message: 'Invitation is valid.', request_id: requestId,
      data: {
        invitation_id: invitation.id,
        signer_name: invitation.signer_name,
        signer_email: invitation.signer_email,
        signer_position: invitation.signer_position,
        clinic: invitation.clinic,
        template: invitation.template,
        expires_at: invitation.expires_at,
      },
    });
  } catch (error) {
    console.error('[get-b2b-invitation]', requestId, error);
    return respond(500, requestId, allowedOrigin, {
      success: false, code: 'INTERNAL_ERROR', message: 'Internal server error.', request_id: requestId,
    });
  }
});
