import { requirePortalRole } from '../_shared/auth.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';

type InvitationFlow = 'registration_required' | 'consent_required' | 'info_only';

type CreateInvitationPayload = {
  email?: unknown;
  session_date?: unknown;
  session_time?: unknown;
  duration_minutes?: unknown;
  recipient_timezone?: unknown;
  registration_base_url?: unknown;
};

type InvitationCreateRpcResponse = {
  status: 'success' | 'error';
  code?: string;
  message?: string;
  flow?: InvitationFlow;
  token?: string;
  invitationId?: string;
};

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function asNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
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

function getStatusCodeFromInviteCode(code?: string) {
  switch (code) {
    case 'AUTH_REQUIRED':
      return 401;
    case 'FORBIDDEN':
      return 403;
    case 'INVALID_CLINIC':
    case 'INVALID_MEMBERSHIP':
    case 'INVALID_EMAIL':
    case 'INVALID_SCHEDULE':
    case 'INVALID_DURATION':
    case 'NO_PRACTITIONER':
      return 400;
    default:
      return 500;
  }
}

Deno.serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  if (req.method !== 'POST') {
    return jsonResponse({
      req,
      requestId,
      status: 400,
      success: false,
      code: 'BAD_REQUEST',
      message: 'Method tidak didukung.',
    });
  }

  try {
    const auth = await requirePortalRole(req);
    if (!auth.ok) {
      return jsonResponse({
        req,
        requestId,
        status: auth.status,
        success: false,
        code: auth.code,
        message: auth.message,
      });
    }

    const payload = (await req.json()) as CreateInvitationPayload;
    const email = asTrimmedString(payload.email).toLowerCase();
    const sessionDate = asTrimmedString(payload.session_date);
    const sessionTime = asTrimmedString(payload.session_time);
    const durationMinutes = asNumber(payload.duration_minutes);
    const recipientTimezone = resolveSessionTimezone(asTrimmedString(payload.recipient_timezone));
    const registrationBaseUrl = asTrimmedString(payload.registration_base_url);

    if (!isValidEmail(email)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Email tidak valid.' });
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(sessionDate)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Tanggal sesi tidak valid.' });
    }
    if (!/^\d{2}:\d{2}$/.test(sessionTime)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Waktu sesi tidak valid.' });
    }
    if (durationMinutes === null || durationMinutes < 15 || durationMinutes > 180) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Durasi sesi tidak valid.' });
    }

    const { data: activeMembership } = await auth.supabase
      .from('clinic_memberships')
      .select('id, clinic_id')
      .eq('user_id', auth.userId)
      .eq('is_active', true)
      .order('is_owner', { ascending: false })
      .order('created_at', { ascending: true })
      .limit(1)
      .maybeSingle<{ id: string; clinic_id: string }>();

    if (!activeMembership) {
      return jsonResponse({ req, requestId, status: 403, success: false, code: 'FORBIDDEN', message: 'Membership klinik aktif tidak ditemukan.' });
    }

    const { data: rpcData, error: rpcError } = await auth.supabase.rpc('create_patient_invitation_with_schedule', {
      target_clinic_id: activeMembership.clinic_id,
      invited_by_membership_id: activeMembership.id,
      patient_email: email,
      session_date: sessionDate,
      session_time: sessionTime,
      duration_minutes: durationMinutes,
      session_timezone: recipientTimezone,
      invitation_ttl_hours: 72,
    });

    if (rpcError) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: `Gagal membuat undangan: ${rpcError.message}` });
    }

    const rpcResult = (rpcData ?? null) as InvitationCreateRpcResponse | null;
    if (!rpcResult) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Gagal membuat undangan karena response server kosong.' });
    }

    if (rpcResult.status === 'error') {
      return jsonResponse({
        req,
        requestId,
        status: getStatusCodeFromInviteCode(rpcResult.code),
        success: false,
        code: 'BAD_REQUEST',
        message: rpcResult.message ?? 'Gagal membuat undangan.',
        data: { flow: rpcResult.flow ?? null },
      });
    }

    if (!rpcResult.invitationId) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'ID undangan tidak ditemukan dari server.' });
    }

    const mailHeaders: HeadersInit = {
      'Content-Type': 'application/json',
      Authorization: req.headers.get('authorization') ?? '',
    };
    const apikey = req.headers.get('apikey');
    if (apikey) {
      mailHeaders.apikey = apikey;
    }

    const mailResponse = await fetch(`${new URL(req.url).origin}/functions/v1/send-patient-invitation`, {
      method: 'POST',
      headers: mailHeaders,
      body: JSON.stringify({
        invitation_id: rpcResult.invitationId,
        registration_base_url: registrationBaseUrl,
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
      const fallbackRegistrationUrl =
        rpcResult.flow === 'info_only' || !rpcResult.token
          ? null
          : `${registrationBaseUrl.replace(/\/$/, '')}/register/${rpcResult.token}`;

      return jsonResponse({
        req,
        requestId,
        status: 200,
        success: true,
        code: 'OK',
        message:
          rpcResult.flow === 'info_only'
            ? 'Undangan tersimpan dan jadwal sesi sudah dibuat, tetapi email notifikasi gagal dikirim.'
            : 'Undangan tersimpan, tetapi pengiriman email gagal. Gunakan link fallback di bawah.',
        data: {
          flow: rpcResult.flow ?? null,
          fallbackRegistrationUrl,
        },
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message:
        rpcResult.flow === 'registration_required'
          ? `Undangan registrasi berhasil dikirim ke ${email}.`
          : rpcResult.flow === 'consent_required'
            ? `Undangan persetujuan data berhasil dikirim ke ${email}.`
            : `Notifikasi jadwal berhasil dikirim ke ${email}.`,
      data: {
        flow: rpcResult.flow ?? null,
        fallbackRegistrationUrl: null,
      },
    });
  } catch (error) {
    console.error('[create-patient-invitation]', requestId, error);
    return jsonResponse({
      req,
      requestId,
      status: 500,
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Terjadi kesalahan saat mengirim undangan.',
    });
  }
});
