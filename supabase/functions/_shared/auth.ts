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
