import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';

type AddressLevel = 'province' | 'city' | 'district' | 'subdistrict' | 'postal_code';

function parseLevel(value: string | null): AddressLevel | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();
  if (
    normalized === 'province' ||
    normalized === 'city' ||
    normalized === 'district' ||
    normalized === 'subdistrict' ||
    normalized === 'postal_code'
  ) {
    return normalized;
  }
  return null;
}

function asPositiveInt(value: string | null): number | null {
  if (!value) return null;
  const parsed = Number.parseInt(value.trim(), 10);
  if (!Number.isInteger(parsed) || parsed <= 0) return null;
  return parsed;
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);

  if (req.method !== 'GET') {
    return jsonResponse({
      req,
      requestId,
      status: 405,
      success: false,
      code: 'BAD_REQUEST',
      message: 'Metode request tidak didukung.',
    });
  }

  try {
    const url = new URL(req.url);
    const levelRaw = url.searchParams.get('level');
    if (!levelRaw) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: "Parameter 'level' is required",
      });
    }

    const level = parseLevel(levelRaw);
    if (!level) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: 'Invalid level value',
      });
    }

    const supabase = createServiceRoleClient();
    const rate = await checkRateLimit({
      supabase,
      functionName: 'address-reference',
      identifier: `ip:${clientIp}`,
      windowSeconds: 60 * 10,
      limit: 240,
    });

    if (!rate.allowed) {
      return jsonResponse({
        req,
        requestId,
        status: 429,
        success: false,
        code: 'RATE_LIMITED',
        message: 'Too many requests',
        data: { retry_after_seconds: rate.retryAfterSeconds },
      });
    }

    const parentId = asPositiveInt(url.searchParams.get('parent_id'));
    const queryMap = {
      province: () =>
        supabase
          .from('address_province')
          .select('id, prov_id, prov_name')
          .order('prov_name', { ascending: true })
          .limit(100),
      city: () =>
        supabase
          .from('address_city')
          .select('id, city_id, city_name')
          .eq('prov_id', parentId as number)
          .order('city_name', { ascending: true })
          .limit(600),
      district: () =>
        supabase
          .from('address_district')
          .select('id, dis_id, dis_name')
          .eq('city_id', parentId as number)
          .order('dis_name', { ascending: true })
          .limit(200),
      subdistrict: () =>
        supabase
          .from('address_subdistrict')
          .select('id, subdis_id, subdis_name')
          .eq('dis_id', parentId as number)
          .order('subdis_name', { ascending: true })
          .limit(200),
      postal_code: () =>
        supabase
          .from('address_postal_code')
          .select('id, postal_id, postal_code')
          .eq('subdis_id', parentId as number)
          .order('postal_code', { ascending: true })
          .limit(10),
    } as const;

    if (level !== 'province' && !parentId) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'BAD_REQUEST',
        message: "Parameter 'parent_id' is required",
      });
    }

    const { data, error } = await queryMap[level]();
    if (error) throw error;

    const items = (data ?? []).map((row) => ({
      id: row.id,
      domain_id:
        level === 'province'
          ? row.prov_id
          : level === 'city'
            ? row.city_id
            : level === 'district'
              ? row.dis_id
              : level === 'subdistrict'
                ? row.subdis_id
                : row.postal_id,
      name:
        level === 'province'
          ? row.prov_name
          : level === 'city'
            ? row.city_name
            : level === 'district'
              ? row.dis_name
              : level === 'subdistrict'
                ? row.subdis_name
                : row.postal_code,
    }));

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Berhasil.',
      data: items,
    });
  } catch (error) {
    console.error('[address-reference]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    });
  }
});
