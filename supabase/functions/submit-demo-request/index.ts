import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';

type DemoRequestPayload = Record<string, unknown>;

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function normalizeWhatsapp(raw: string): string {
  return raw.replace(/\D/g, '');
}

function isValidWhatsapp(value: string): boolean {
  return /^\d{10,13}$/.test(value);
}

function asUuid(value: unknown): string | null {
  const text = asTrimmedString(value);
  if (!text) return null;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(text)
    ? text
    : null;
}

function renderInternalMail(payload: Record<string, string>) {
  return `
    <h1>Demo Request Baru</h1>
    <p><strong>Clinic:</strong> ${payload.clinic_name}</p>
    <p><strong>PIC:</strong> ${payload.pic_name}</p>
    <p><strong>Role:</strong> ${payload.pic_role}</p>
    <p><strong>Email:</strong> ${payload.email}</p>
    <p><strong>WhatsApp:</strong> ${payload.whatsapp}</p>
    <p><strong>Address:</strong> ${payload.address}</p>
    <p><strong>Referral Source:</strong> ${payload.referral_source}</p>
    <p><strong>Message:</strong> ${payload.message}</p>
  `;
}

function renderSubmitterMail(picName: string, clinicName: string) {
  return `
    <h1>Terima kasih, ${picName}!</h1>
    <p>Permintaan demo untuk <strong>${clinicName}</strong> sudah kami terima.</p>
    <p>Tim Catatan Psikolog akan menghubungi Anda untuk langkah berikutnya.</p>
  `;
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);

  if (req.method !== 'POST') {
    return jsonResponse({ req, requestId, status: 405, success: false, code: 'BAD_REQUEST', message: 'Metode request tidak didukung.' });
  }

  try {
    const payload = (await req.json()) as DemoRequestPayload;
    const clinicName = asTrimmedString(payload.clinic_name);
    const clinicType = asTrimmedString(payload.clinic_type);
    const picName = asTrimmedString(payload.pic_name);
    const picRole = asTrimmedString(payload.pic_role);
    const email = asTrimmedString(payload.email).toLowerCase();
    const whatsapp = normalizeWhatsapp(asTrimmedString(payload.whatsapp));
    const provinceId = asUuid(payload.province_id);
    const cityId = asUuid(payload.city_id);
    const districtId = asUuid(payload.district_id);
    const subdistrictId = asUuid(payload.subdistrict_id);
    const postalCodeId = asUuid(payload.postal_code_id);
    const provinceName = asTrimmedString(payload.province_name);
    const cityName = asTrimmedString(payload.city_name);
    const districtName = asTrimmedString(payload.district_name);
    const subdistrictName = asTrimmedString(payload.subdistrict_name);
    const postalCode = asTrimmedString(payload.postal_code);
    const message = asTrimmedString(payload.message);
    const referralSource = asTrimmedString(payload.referral_source);

    if (!clinicName || !picName || !email || !whatsapp) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: clinic_name, pic_name, email, whatsapp wajib diisi.' });
    }
    if (!isValidEmail(email)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: format email tidak valid.' });
    }
    if (!isValidWhatsapp(whatsapp)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: whatsapp harus 10-13 digit numerik.' });
    }

    const supabase = createServiceRoleClient();
    const rate = await checkRateLimit({
      supabase,
      functionName: 'submit-demo-request',
      identifier: `ip:${clientIp}`,
      windowSeconds: 60 * 60,
      limit: 10,
    });
    if (!rate.allowed) {
      return jsonResponse({ req, requestId, status: 429, success: false, code: 'RATE_LIMITED', message: 'Terlalu banyak permintaan' });
    }

    const { data, error } = await supabase
      .from('demo_requests')
      .insert({
        clinic_name: clinicName,
        clinic_type: clinicType || null,
        pic_name: picName,
        pic_role: picRole || null,
        email,
        whatsapp,
        province_id: provinceId,
        city_id: cityId,
        district_id: districtId,
        subdistrict_id: subdistrictId,
        postal_code_id: postalCodeId,
        province_name: provinceName || null,
        city_name: cityName || null,
        district_name: districtName || null,
        subdistrict_name: subdistrictName || null,
        postal_code: postalCode || null,
        message: message || null,
        referral_source: referralSource || null,
      })
      .select('id')
      .single();

    if (error) throw error;

    try {
      await dispatchMail({
        requestId,
        to: 'support@catatanpsikolog.id',
        subject: `Demo Request Baru: ${clinicName}`,
        html: renderInternalMail({
          clinic_name: clinicName,
          pic_name: picName,
          pic_role: picRole || '-',
          email,
          whatsapp,
          address: [provinceName, cityName, districtName, subdistrictName, postalCode].filter(Boolean).join(', ') || '-',
          referral_source: referralSource || '-',
          message: message || '-',
        }),
      });

      await dispatchMail({
        requestId,
        to: email,
        subject: `Terima kasih, ${picName}! Permintaan demo Anda telah diterima`,
        html: renderSubmitterMail(picName, clinicName),
      });
    } catch (mailError) {
      console.error('[submit-demo-request] mail dispatch warning', requestId, mailError);
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Demo request submitted successfully',
      data: { id: data.id },
    });
  } catch (error) {
    console.error('[submit-demo-request]', requestId, error);
    return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Internal server error' });
  }
});
