import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { clientIpFrom } from './http.ts';

function resolveServiceRoleKey(): string {
  const candidates = [
    Deno.env.get('EDGE_AUTH_SERVICE_ROLE_JWT') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    Deno.env.get('SUPABASE_SECRET_KEY') ?? '',
  ].map((value) => value.trim());

  for (const key of candidates) {
    if (!key) continue;
    if (key.startsWith('sb_publishable_')) continue;
    return key;
  }

  throw new Error('Missing valid service-role/secret key for edge function admin client.');
}

export type RateLimitDecision = {
  allowed: boolean;
  currentCount: number;
  retryAfterSeconds: number;
};

export type LegacyRateLimitDecision = {
  limited: boolean;
  retryAfterSeconds: number;
};

export function createServiceRoleClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    resolveServiceRoleKey(),
  );
}

export function getClientIp(req: Request): string {
  return clientIpFrom(req);
}

async function checkRateLimitObject(params: {
  supabase: ReturnType<typeof createServiceRoleClient>;
  functionName: string;
  identifier: string;
  windowSeconds: number;
  limit: number;
}): Promise<RateLimitDecision> {
  const { data, error } = await params.supabase.rpc('edge_check_rate_limit', {
    p_function_name: params.functionName,
    p_identifier: params.identifier,
    p_window_seconds: params.windowSeconds,
    p_limit: params.limit,
  });

  if (error) throw error;

  const row = Array.isArray(data) ? data[0] : null;
  if (!row) {
    throw new Error('edge_check_rate_limit returned empty result.');
  }

  return {
    allowed: !!row.allowed,
    currentCount: Number(row.current_count ?? 0),
    retryAfterSeconds: Number(row.retry_after_seconds ?? 0),
  };
}

export function checkRateLimit(
  params: {
    supabase: ReturnType<typeof createServiceRoleClient>;
    functionName: string;
    identifier: string;
    windowSeconds: number;
    limit: number;
  },
): Promise<RateLimitDecision>;
export function checkRateLimit(
  service: ReturnType<typeof createServiceRoleClient>,
  identifier: string,
  fnName: string,
  windowMinutes: number,
  maxRequests: number,
): Promise<LegacyRateLimitDecision>;
export async function checkRateLimit(
  serviceOrParams:
    | {
        supabase: ReturnType<typeof createServiceRoleClient>;
        functionName: string;
        identifier: string;
        windowSeconds: number;
        limit: number;
      }
    | ReturnType<typeof createServiceRoleClient>,
  identifier?: string,
  fnName?: string,
  windowMinutes?: number,
  maxRequests?: number,
): Promise<RateLimitDecision | LegacyRateLimitDecision> {
  if (
    typeof serviceOrParams === 'object' &&
    serviceOrParams !== null &&
    'supabase' in serviceOrParams
  ) {
    return checkRateLimitObject(serviceOrParams);
  }

  const result = await checkRateLimitObject({
    supabase: serviceOrParams,
    identifier: identifier ?? 'unknown',
    functionName: fnName ?? 'unknown',
    windowSeconds: Math.max(1, Math.trunc((windowMinutes ?? 1) * 60)),
    limit: Math.max(1, Math.trunc(maxRequests ?? 1)),
  });

  return {
    limited: !result.allowed,
    retryAfterSeconds: result.retryAfterSeconds,
  };
}
