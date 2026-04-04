const DEFAULT_ALLOWED_ORIGINS = [
  'https://www.catatanpsikolog.id',
  'https://catatanpsikolog.id',
  'https://app.catatanpsikolog.id',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
] as const;

const CORS_ALLOW_HEADERS =
  'authorization, x-client-info, apikey, content-type, x-request-id';
const CORS_ALLOW_METHODS = 'POST, OPTIONS';

function resolveAllowedOrigins(): Set<string> {
  const configured = (Deno.env.get('EDGE_ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  return new Set(configured.length > 0 ? configured : DEFAULT_ALLOWED_ORIGINS);
}

function resolveAllowedOrigin(req: Request): string | null {
  const origin = req.headers.get('origin')?.trim();
  if (!origin) return null;
  return resolveAllowedOrigins().has(origin) ? origin : null;
}

const responseSecurityHeaders = {
  'Cache-Control': 'no-store',
  Pragma: 'no-cache',
  'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff',
};

function buildCorsHeaders(req: Request): Record<string, string> {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers': CORS_ALLOW_HEADERS,
    'Access-Control-Allow-Methods': CORS_ALLOW_METHODS,
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };

  const allowedOrigin = resolveAllowedOrigin(req);
  if (allowedOrigin) {
    headers['Access-Control-Allow-Origin'] = allowedOrigin;
  }

  return headers;
}

export type ApiCode =
  | 'OK'
  | 'BAD_REQUEST'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'INTERNAL_ERROR';

export function requestIdFrom(req: Request): string {
  return req.headers.get('x-request-id')?.trim() || crypto.randomUUID();
}

export function preflight(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        ...buildCorsHeaders(req),
        ...responseSecurityHeaders,
      },
    });
  }
  return null;
}

export function jsonResponse(params: {
  req: Request;
  requestId: string;
  status: number;
  success: boolean;
  code: ApiCode;
  message: string;
  data?: unknown;
}): Response {
  const body = {
    success: params.success,
    code: params.code,
    message: params.message,
    data: params.data ?? null,
    request_id: params.requestId,
    timestamp: new Date().toISOString(),
  };

  return new Response(JSON.stringify(body), {
    status: params.status,
    headers: {
      ...buildCorsHeaders(params.req),
      ...responseSecurityHeaders,
      'Content-Type': 'application/json',
      'x-request-id': params.requestId,
    },
  });
}
