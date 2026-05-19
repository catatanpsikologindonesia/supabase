import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type AllowedRole = 'clinic_staff';

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

export function createServiceRoleClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  if (!supabaseUrl) {
    throw new Error('SUPABASE_URL is not configured.');
  }

  return createClient(supabaseUrl, resolveServiceRoleKey());
}

function resolvePublicAnonKey(req: Request): string {
  const headerKey = req.headers.get('apikey')?.trim() ?? '';
  const envCandidates = [
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ?? '',
  ].map((value) => value.trim());

  for (const key of [headerKey, ...envCandidates]) {
    if (!key) continue;
    return key;
  }

  throw new Error('Missing anon/publishable key for authenticated edge client.');
}

export function createRequestAuthClient(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  if (!supabaseUrl) {
    throw new Error('SUPABASE_URL is not configured.');
  }

  const authHeader = req.headers.get('authorization')?.trim() ?? '';
  return createClient(supabaseUrl, resolvePublicAnonKey(req), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: authHeader
      ? {
          headers: {
            Authorization: authHeader,
          },
        }
      : undefined,
  });
}

export async function requirePortalRole(
  req: Request,
): Promise<
  | { ok: true; userId: string; role: AllowedRole; supabase: ReturnType<typeof createServiceRoleClient> }
  | { ok: false; status: number; code: 'UNAUTHORIZED' | 'FORBIDDEN'; message: string }
> {
  const authHeader = req.headers.get('authorization')?.trim() ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return {
      ok: false,
      status: 401,
      code: 'UNAUTHORIZED',
      message: 'Token sesi tidak ditemukan.',
    };
  }

  const supabase = createServiceRoleClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser(token);

  if (userError || !user) {
    return {
      ok: false,
      status: 401,
      code: 'UNAUTHORIZED',
      message: 'Sesi login tidak valid atau sudah berakhir.',
    };
  }

  const { data: profile, error: profileError } = await supabase
    .from('users')
    .select('role')
    .eq('id', user.id)
    .maybeSingle<{ role: AllowedRole | 'patient' | null }>();

  if (profileError || !profile || profile.role !== 'clinic_staff') {
    return {
      ok: false,
      status: 403,
      code: 'FORBIDDEN',
      message: 'Akses ditolak. Hanya staf klinik yang diizinkan.',
    };
  }

  return {
    ok: true,
    userId: user.id,
    role: profile.role,
    supabase,
  };
}

function createAuthResponse(
  status: number,
  code: 'UNAUTHORIZED' | 'FORBIDDEN' | 'INTERNAL_ERROR',
  message: string,
): Response {
  return new Response(
    JSON.stringify({ success: false, code, message }),
    {
      status,
      headers: {
        'Content-Type': 'application/json',
      },
    },
  );
}

export async function requireAdminRole(
  req: Request,
  minRole: 'STAFF' | 'ADMIN' | 'SUPER_ADMIN' = 'STAFF',
): Promise<
  | { ok: true; userId: string; supabase: ReturnType<typeof createServiceRoleClient>; caller: ReturnType<typeof createClient> }
  | { ok: false; response: Response }
> {
  const authHeader = req.headers.get('authorization')?.trim() ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return { ok: false, response: createAuthResponse(401, 'UNAUTHORIZED', 'Authorization header is required.') };
  }

  const serviceSupabase = createServiceRoleClient();
  const { data: { user }, error: userError } = await serviceSupabase.auth.getUser(token);
  if (userError || !user) {
    return { ok: false, response: createAuthResponse(401, 'UNAUTHORIZED', 'Unauthorized.') };
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const supabaseAnonKey =
    Deno.env.get('SUPABASE_ANON_KEY')?.trim() ||
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY')?.trim() ||
    '';
  if (!supabaseUrl || !supabaseAnonKey) {
    return { ok: false, response: createAuthResponse(500, 'INTERNAL_ERROR', 'Internal server error.') };
  }

  const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      headers: { Authorization: authHeader, apikey: supabaseAnonKey },
    },
  });

  const { data: isAdmin, error: adminError } = await callerClient.rpc('is_admin_at_least', { p_min_role: minRole });
  if (adminError || !isAdmin) {
    return { ok: false, response: createAuthResponse(403, 'FORBIDDEN', 'Caller is not an LBSD admin.') };
  }

  return { ok: true, userId: user.id, supabase: serviceSupabase, caller: callerClient };
}
