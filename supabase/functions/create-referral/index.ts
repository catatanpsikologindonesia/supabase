import { requirePortalRole } from '../_shared/auth.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';

type CreateReferralPayload = {
  clinic_id?: unknown;
  patient_id?: unknown;
  visit_id?: unknown;
  destination?: unknown;
  notes?: unknown;
  expires_at?: unknown;
  recipient_timezone?: unknown;
  portal_base_url?: unknown;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function generatePin() {
  const bytes = new Uint32Array(1);
  crypto.getRandomValues(bytes);
  return (bytes[0] % 1_000_000).toString().padStart(6, '0');
}

function resolveSessionTimezone(timezone?: string) {
  const candidate = timezone?.trim();
  if (!candidate) return 'Asia/Jakarta';

  try {
    new Intl.DateTimeFormat('id-ID', { timeZone: candidate }).format(new Date());
    return candidate;
  } catch {
    return 'Asia/Jakarta';
  }
}

Deno.serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  if (req.method !== 'POST') {
    return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Method tidak didukung.' });
  }

  try {
    const auth = await requirePortalRole(req);
    if (!auth.ok) {
      return jsonResponse({ req, requestId, status: auth.status, success: false, code: auth.code, message: auth.message });
    }

    const payload = (await req.json()) as CreateReferralPayload;
    const clinicId = asTrimmedString(payload.clinic_id);
    const patientId = asTrimmedString(payload.patient_id);
    const visitId = asTrimmedString(payload.visit_id);
    const destination = asTrimmedString(payload.destination);
    const notes = asTrimmedString(payload.notes);
    const expiresAtRaw = asTrimmedString(payload.expires_at);
    const recipientTimezone = resolveSessionTimezone(asTrimmedString(payload.recipient_timezone));
    const portalBaseUrl = asTrimmedString(payload.portal_base_url);

    if (!clinicId || !patientId || !visitId || destination.length < 2 || notes.length < 5 || !expiresAtRaw || !portalBaseUrl) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Input tidak valid.' });
    }

    const { data: membership } = await auth.supabase
      .from('clinic_memberships')
      .select('id')
      .eq('user_id', auth.userId)
      .eq('clinic_id', clinicId)
      .eq('is_active', true)
      .eq('is_practitioner', true)
      .limit(1)
      .maybeSingle<{ id: string }>();

    if (!membership) {
      return jsonResponse({ req, requestId, status: 403, success: false, code: 'FORBIDDEN', message: 'Akses practitioner untuk klinik aktif tidak ditemukan.' });
    }

    const expiresAt = new Date(expiresAtRaw);
    if (Number.isNaN(expiresAt.getTime())) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Tanggal kedaluwarsa referral tidak valid.' });
    }

    const [{ data: clinicPatient }, { data: visit }] = await Promise.all([
      auth.supabase.from('clinic_patients').select('id').eq('clinic_id', clinicId).eq('patient_id', patientId).maybeSingle<{ id: string }>(),
      auth.supabase.from('patient_visits').select('id').eq('id', visitId).eq('clinic_id', clinicId).eq('patient_id', patientId).maybeSingle<{ id: string }>(),
    ]);

    if (!clinicPatient) {
      return jsonResponse({ req, requestId, status: 404, success: false, code: 'BAD_REQUEST', message: 'Pasien tidak terdaftar pada klinik aktif.' });
    }
    if (!visit) {
      return jsonResponse({ req, requestId, status: 404, success: false, code: 'BAD_REQUEST', message: 'Visit tidak ditemukan pada klinik aktif.' });
    }

    const { data: patient, error: patientError } = await auth.supabase
      .from('patients')
      .select('id, full_name, email')
      .eq('id', patientId)
      .maybeSingle<{ id: string; full_name: string | null; email: string | null }>();

    if (patientError || !patient) {
      return jsonResponse({ req, requestId, status: 404, success: false, code: 'BAD_REQUEST', message: 'Data pasien tidak ditemukan.' });
    }

    const pin = generatePin();
    const { data: referral, error: referralError } = await auth.supabase
      .from('referrals_and_feedback')
      .insert({
        clinic_id: clinicId,
        visit_id: visitId,
        patient_id: patientId,
        practitioner_membership_id: membership.id,
        destination,
        notes,
        secure_pin: pin,
        expires_at: expiresAt.toISOString(),
      })
      .select('id')
      .single<{ id: string }>();

    if (referralError || !referral) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: `Gagal membuat referral: ${referralError?.message ?? 'unknown error'}` });
    }

    if (!patient.email) {
      return jsonResponse({
        req,
        requestId,
        status: 200,
        success: true,
        code: 'OK',
        message: 'Referral dibuat, tetapi email pasien kosong. PIN ditampilkan sebagai fallback.',
        data: { generatedPin: pin },
      });
    }

    const mailHeaders: HeadersInit = {
      'Content-Type': 'application/json',
      Authorization: req.headers.get('authorization') ?? '',
    };
    const apikey = req.headers.get('apikey');
    if (apikey) {
      mailHeaders.apikey = apikey;
    }

    const mailResponse = await fetch(`${new URL(req.url).origin}/functions/v1/send-referral-pin`, {
      method: 'POST',
      headers: mailHeaders,
      body: JSON.stringify({
        referral_id: referral.id,
        portal_base_url: portalBaseUrl,
        recipient_timezone: recipientTimezone,
      }),
    });

    const mailText = await mailResponse.text();
    let mailPayload: Record<string, unknown> | null = null;
    try {
      mailPayload = mailText ? JSON.parse(mailText) as Record<string, unknown> : null;
    } catch {
      mailPayload = null;
    }

    if (!mailResponse.ok || mailPayload?.success === false) {
      return jsonResponse({
        req,
        requestId,
        status: 200,
        success: true,
        code: 'OK',
        message: 'Referral tersimpan, tetapi email PIN gagal dikirim. Gunakan PIN fallback di bawah.',
        data: { generatedPin: pin },
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: 'Referral berhasil dibuat dan PIN dikirim ke email pasien.',
      data: { generatedPin: pin },
    });
  } catch (error) {
    console.error('[create-referral]', requestId, error);
    return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Terjadi kesalahan saat membuat referral.' });
  }
});
