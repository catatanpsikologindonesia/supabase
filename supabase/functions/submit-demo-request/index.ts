import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { clientIpFrom, jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { dispatchMail } from '../_shared/mail_dispatcher.ts';
import { checkRateLimit, createServiceRoleClient } from '../_shared/rate_limit.ts';

const DEMO_ADMIN_RECIPIENT = 'support@catatanpsikolog.id';
const DEMO_EMAIL_BRAND_NAME = 'Catatan Psikolog Support';
const BRAND_GRADIENT = 'background:#7B7BBB; background-image:linear-gradient(135deg,#5a5a99 0%,#7B7BBB 55%,#A5A5D3 100%)';
const BRAND_TABLE_BG = '#f7f7fc';
const BRAND_TABLE_BORDER = '#d4d4ec';

function escapeHtml(v: string): string {
  return v.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
}
function safe(v: string | null | undefined): string { return String(v ?? '').trim() || '-'; }
function waLink(raw: string): string {
  const d = raw.replace(/\D/g,''); if (!d) return 'https://wa.me/';
  return d.startsWith('0') ? `https://wa.me/62${d.slice(1)}` : `https://wa.me/${d}`;
}
function fmtDate(iso: string): string {
  const p = new Date(iso); if (isNaN(p.getTime())) return iso;
  return new Intl.DateTimeFormat('id-ID',{timeZone:'Asia/Jakarta',day:'2-digit',month:'long',year:'numeric',hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false}).format(p).replace('.', ':');
}

type EmailVars = {
  requestId: string; submittedAt: string; fullname: string; position: string;
  email: string; whatsapp: string; clinicName: string; clinicType: string;
  addressLine: string; rtRw: string; subdistrict: string; district: string;
  city: string; province: string; postalCode: string;
  referralSource: string | null; message: string | null;
  subscribe: boolean; privacy: boolean;
};

function buildAdminEmail(v: EmailVars): { subject: string; html: string } {
  const e = (s: string) => escapeHtml(safe(s));
  const row = (label: string, val: string) =>
    `<tr><td style="padding:10px;width:34%;background:${BRAND_TABLE_BG};border:1px solid ${BRAND_TABLE_BORDER};">${label}</td><td style="padding:10px;border:1px solid ${BRAND_TABLE_BORDER};">${val}</td></tr>`;
  return {
    subject: `Permintaan Demo Baru - ${safe(v.clinicName)} | ${safe(v.requestId)}`,
    html: `<!DOCTYPE html><html lang="id"><body style="margin:0;padding:0;background:#eeeef6;font-family:Arial,sans-serif;color:#1f2937;">
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#eeeef6;padding:24px 12px;"><tr><td align="center">
<table cellpadding="0" cellspacing="0" border="0" width="700" style="max-width:700px;background:#fff;border:1px solid ${BRAND_TABLE_BORDER};border-radius:16px;overflow:hidden;">
<tr><td style="padding:22px 26px;${BRAND_GRADIENT};"><h2 style="margin:0;color:#fff;font-size:24px;">Permintaan Demo Baru</h2>
<p style="margin:8px 0 0;color:#fff;font-size:13px;">Sumber: <a href="https://www.catatanpsikolog.id" style="color:#fff;text-decoration:underline;">https://www.catatanpsikolog.id</a></p></td></tr>
<tr><td style="padding:22px 26px;"><table cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse:collapse;">
${row('Nama Lengkap', e(v.fullname))}${row('Jabatan', e(v.position))}${row('Email', e(v.email))}${row('WhatsApp', e(v.whatsapp))}
${row('Nama Praktik/Biro', e(v.clinicName))}${row('Jenis Praktik', e(v.clinicType))}
${row('Alamat Praktik', e(v.addressLine))}${row('RT/RW', e(v.rtRw))}
${row('Kelurahan/Desa', e(v.subdistrict))}${row('Kecamatan', e(v.district))}${row('Kota/Kab', e(v.city))}${row('Provinsi', e(v.province))}${row('Kode Pos', e(v.postalCode))}
${row('Sumber Info', escapeHtml(safe(v.referralSource)))}${row('Pesan', escapeHtml(safe(v.message)))}
${row('Berlangganan', v.subscribe ? 'Ya' : 'Tidak')}${row('Setuju Kebijakan Privasi', v.privacy ? 'Ya' : 'Tidak')}
${row('Kode Pengajuan', `<strong>${e(v.requestId)}</strong>`)}${row('Waktu Pengajuan', escapeHtml(fmtDate(v.submittedAt)))}
</table>
<table cellpadding="0" cellspacing="0" border="0" style="margin-top:18px;"><tr><td style="border-radius:10px;${BRAND_GRADIENT};">
<a href="${escapeHtml(waLink(v.whatsapp))}" style="display:inline-block;padding:12px 18px;font-size:14px;font-weight:700;color:#fff;text-decoration:none;border-radius:10px;">Hubungi via WhatsApp</a>
</td></tr></table></td></tr>
<tr><td style="padding:14px 20px;background:#f1f1f8;border-top:1px solid ${BRAND_TABLE_BORDER};text-align:center;color:#64748b;font-size:12px;">
&copy; ${new Date().getFullYear()} PT Lintas Buana Sistem Digital. Catatan Psikolog. Hak cipta dilindungi.</td></tr>
</table></td></tr></table></body></html>`,
  };
}

function buildUserEmail(v: EmailVars): { subject: string; html: string } {
  const e = (s: string) => escapeHtml(safe(s));
  return {
    subject: `Konfirmasi Pengajuan Demo Catatan Psikolog | ${safe(v.requestId)}`,
    html: `<!DOCTYPE html><html lang="id"><body style="margin:0;padding:0;background:#eeeef6;font-family:Arial,sans-serif;color:#1f2937;">
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#eeeef6;padding:22px 10px;"><tr><td align="center">
<table cellpadding="0" cellspacing="0" border="0" width="620" style="max-width:620px;background:#fff;border:1px solid ${BRAND_TABLE_BORDER};border-radius:16px;overflow:hidden;">
<tr><td style="padding:0;${BRAND_GRADIENT};">
<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td style="padding:24px 26px 20px;">
<div style="display:inline-block;padding:7px 18px;border:2px solid rgba(255,255,255,0.55);border-radius:999px;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#fff;">CATATAN PSIKOLOG</div>
<h1 style="margin:16px 0 10px;font-size:28px;line-height:1.05;color:#fff;font-weight:700;">Konfirmasi Pengajuan Demo</h1>
<p style="margin:0;font-size:14px;line-height:1.5;color:rgba(255,255,255,0.96);">Pengajuan Anda telah kami terima dan sedang diproses oleh tim Catatan Psikolog.</p>
</td></tr></table></td></tr>
<tr><td style="padding:22px 24px 10px;">
<p style="margin:0 0 12px;font-size:15px;line-height:1.7;">Halo <strong>${e(v.fullname)}</strong>,</p>
<p style="margin:0;font-size:15px;line-height:1.7;color:#374151;">Terima kasih atas ketertarikan Anda. Pengajuan demo untuk <strong>${e(v.clinicName)}</strong> telah berhasil kami catat.</p>
</td></tr>
<tr><td style="padding:0 24px 12px;">
<table cellpadding="0" cellspacing="0" border="0" width="100%" style="background:${BRAND_TABLE_BG};border:1px solid ${BRAND_TABLE_BORDER};border-radius:12px;"><tr><td style="padding:14px 16px;">
<div style="font-size:11px;color:#5a5a99;margin-bottom:6px;text-transform:uppercase;letter-spacing:0.7px;">Kode Pengajuan</div>
<div style="font-size:22px;font-weight:700;color:#0f172a;">${e(v.requestId)}</div>
<div style="margin-top:7px;font-size:12px;color:#60727a;">Simpan kode ini untuk keperluan tindak lanjut.</div>
</td></tr></table></td></tr>
<tr><td style="padding:4px 24px 10px;"><table cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse:collapse;">
<tr><td style="padding:9px 0;border-bottom:1px solid #edf2f4;font-size:13px;color:#64748b;width:44%;">Nama Praktik/Biro</td><td style="padding:9px 0;border-bottom:1px solid #edf2f4;font-size:13px;color:#0f172a;font-weight:600;">${e(v.clinicName)}</td></tr>
<tr><td style="padding:9px 0;border-bottom:1px solid #edf2f4;font-size:13px;color:#64748b;">Nomor WhatsApp</td><td style="padding:9px 0;border-bottom:1px solid #edf2f4;font-size:13px;color:#0f172a;font-weight:600;">${e(v.whatsapp)}</td></tr>
<tr><td style="padding:9px 0;font-size:13px;color:#64748b;">Waktu Pengajuan</td><td style="padding:9px 0;font-size:13px;color:#0f172a;font-weight:600;">${escapeHtml(fmtDate(v.submittedAt))}</td></tr>
</table></td></tr>
<tr><td style="padding:10px 24px 22px;"><p style="margin:0;font-size:15px;line-height:1.7;color:#374151;">Kami akan menghubungi Anda melalui WhatsApp untuk penjadwalan sesi demo.</p></td></tr>
<tr><td style="padding:16px 24px;background:#f8f8fc;border-top:1px solid #e0e0f0;">
<p style="margin:0 0 4px;font-size:14px;color:#111827;font-weight:700;">Salam hangat,</p>
<p style="margin:0;font-size:14px;color:#1f2937;">${escapeHtml(DEMO_EMAIL_BRAND_NAME)}<br /><a href="https://www.catatanpsikolog.id" style="color:#5a5a99;text-decoration:none;">www.catatanpsikolog.id</a></p>
</td></tr>
<tr><td style="padding:12px 18px;background:#f1f1f8;border-top:1px solid ${BRAND_TABLE_BORDER};text-align:center;color:#64748b;font-size:12px;">
&copy; ${new Date().getFullYear()} PT Lintas Buana Sistem Digital. Catatan Psikolog. Hak cipta dilindungi.</td></tr>
</table></td></tr></table></body></html>`,
  };
}

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

function pad2(value: number): string {
  return value.toString().padStart(2, '0');
}

function generateRequestId(submittedAtUtc: string): string {
  const date = new Date(submittedAtUtc);
  const datePart = `${date.getUTCFullYear()}${pad2(date.getUTCMonth() + 1)}${pad2(date.getUTCDate())}`;
  const timePart = `${pad2(date.getUTCHours())}${pad2(date.getUTCMinutes())}${pad2(date.getUTCSeconds())}`;
  const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = new Uint8Array(4);
  crypto.getRandomValues(bytes);
  const randomPart = Array.from(bytes, (b) => charset[b % charset.length]).join('');
  return `CP-DR-${datePart}-${timePart}-${randomPart}`;
}

serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  const clientIp = clientIpFrom(req);
  const userAgent = req.headers.get('user-agent') ?? '';

  if (req.method !== 'POST') {
    return jsonResponse({ req, requestId, status: 405, success: false, code: 'BAD_REQUEST', message: 'Metode request tidak didukung.' });
  }

  try {
    const payload = (await req.json()) as DemoRequestPayload;

    const clinicName    = asTrimmedString(payload.clinic_name);
    const clinicType    = asTrimmedString(payload.clinic_type);
    const fullname      = asTrimmedString(payload.fullname) || asTrimmedString(payload.pic_name);
    const position      = asTrimmedString(payload.position) || asTrimmedString(payload.pic_role);
    const email         = asTrimmedString(payload.email).toLowerCase();
    const whatsapp      = normalizeWhatsapp(asTrimmedString(payload.whatsapp));
    const addressLine   = asTrimmedString(payload.address_line);
    const rtRw          = asTrimmedString(payload.rt_rw);
    const provinceId    = asUuid(payload.province_id);
    const cityId        = asUuid(payload.city_id);
    const districtId    = asUuid(payload.district_id);
    const subdistrictId = asUuid(payload.subdistrict_id);
    const postalCodeId  = asUuid(payload.postal_code_id);
    const provinceName    = asTrimmedString(payload.province_name);
    const cityName        = asTrimmedString(payload.city_name);
    const districtName    = asTrimmedString(payload.district_name);
    const subdistrictName = asTrimmedString(payload.subdistrict_name);
    const postalCode      = asTrimmedString(payload.postal_code);
    const message         = asTrimmedString(payload.message);
    const referralSource  = asTrimmedString(payload.referral_source);
    const subscribe       = payload.subscribe === true;
    const privacy         = payload.privacy === true;

    // Validation
    if (!clinicName || !fullname || !position || !email || !whatsapp) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: clinic_name, fullname, position, email, whatsapp wajib diisi.' });
    }
    if (!addressLine) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: address_line wajib diisi.' });
    }
    if (!rtRw) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: rt_rw wajib diisi.' });
    }
    if (!privacy) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Validation error: Persetujuan Kebijakan Privasi wajib diisi.' });
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

    const submittedAtUtc = new Date().toISOString();
    const demoRequestId = generateRequestId(submittedAtUtc);

    const { data, error } = await supabase
      .from('demo_requests')
      .insert({
        clinic_name:        clinicName,
        clinic_type:        clinicType || null,
        pic_name:           fullname,
        pic_role:           position || null,
        fullname:           fullname,
        position:           position || null,
        email,
        whatsapp,
        address_line:       addressLine || null,
        rt_rw:              rtRw || null,
        subscribe,
        privacy,
        province_id:        provinceId,
        city_id:            cityId,
        district_id:        districtId,
        subdistrict_id:     subdistrictId,
        postal_code_id:     postalCodeId,
        province_name:      provinceName || null,
        city_name:          cityName || null,
        district_name:      districtName || null,
        subdistrict_name:   subdistrictName || null,
        postal_code:        postalCode || null,
        message:            message || null,
        referral_source:    referralSource || null,
        status:             'pending',
        submitted_at:       submittedAtUtc,
        client_ip:          clientIp,
        user_agent:         userAgent,
      })
      .select('id')
      .single();

    if (error) throw error;

    // Email dispatch — identical pattern to Catatan Dokter
    const emailInput: EmailVars = {
      requestId: demoRequestId,
      submittedAt: submittedAtUtc,
      fullname,
      position,
      email,
      whatsapp,
      clinicName,
      clinicType,
      addressLine,
      rtRw,
      subdistrict: subdistrictName,
      district: districtName,
      city: cityName,
      province: provinceName,
      postalCode,
      referralSource: referralSource || null,
      message: message || null,
      subscribe,
      privacy,
    };

    let emailStatus: 'sent' | 'failed' = 'sent';
    let emailErrorMsg: string | null = null;

    try {
      const adminEmail = buildAdminEmail(emailInput);
      await dispatchMail({
        requestId: `${requestId}-admin`,
        to: DEMO_ADMIN_RECIPIENT,
        subject: adminEmail.subject,
        html: adminEmail.html,
        useCustomFrom: false,
      });

      const userEmail = buildUserEmail(emailInput);
      await dispatchMail({
        requestId: `${requestId}-user`,
        to: email,
        subject: userEmail.subject,
        html: userEmail.html,
      });
    } catch (mailError) {
      emailStatus = 'failed';
      emailErrorMsg = mailError instanceof Error ? mailError.message : 'Unknown mail dispatch error';
      console.error('[submit-demo-request] mail dispatch warning', requestId, mailError);
    }

    // Update email delivery status
    try {
      await supabase
        .from('demo_requests')
        .update({
          email_delivery_status: emailStatus,
          email_delivery_error: emailErrorMsg,
        })
        .eq('id', data.id);
    } catch (_updateError) {
      // Non-fatal — row already inserted
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: emailStatus === 'sent'
        ? 'Permintaan demo berhasil dikirim. Tim kami akan segera menghubungi Anda.'
        : 'Permintaan demo berhasil disimpan. Email konfirmasi sedang dalam proses.',
      data: { id: data.id, request_id: demoRequestId },
    });

  } catch (error) {
    console.error('[submit-demo-request]', requestId, error);
    return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Internal server error' });
  }
});
