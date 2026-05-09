import { createRequestAuthClient, requirePortalRole } from '../_shared/auth.ts';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';
import { isMailDispatchError } from '../_shared/mail_flow_errors.ts';
import { sendPatientInvitationMail } from '../_shared/patient_invitation_mail.ts';

type InvitationFlow = 'registration_required' | 'consent_required' | 'info_only';
type ContactType = 'email' | 'phone';
type RecipientType = 'client' | 'admin';

type CreateInvitationPayload = {
  clinic_id?: unknown;
  email?: unknown;
  phone?: unknown;
  contact_type?: unknown;
  recipient_type?: unknown;
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

function normalizeWhatsappTarget(rawPhone: string): string {
  const digits = rawPhone.replace(/\D/g, '');
  if (!digits) return '';
  if (digits.startsWith('0')) return `62${digits.slice(1)}`;
  if (digits.startsWith('62')) return digits;
  return digits;
}

function buildWhatsappInvitationMessage(params: {
  clinicName: string;
  registrationUrl: string | null;
  flow: InvitationFlow | null | undefined;
  sessionDate: string;
  sessionTime: string;
  timezone: string;
}): string {
  const scheduleLine = `Jadwal sesi: ${params.sessionDate} ${params.sessionTime} (${params.timezone})`;
  if (params.flow === 'info_only') {
    return [
      `Halo, berikut adalah pengingat jadwal sesi Anda bersama ${params.clinicName}.`,
      scheduleLine,
      'Jika ada perubahan jadwal atau kebutuhan lain, silakan hubungi klinik Anda.',
    ].join('\n');
  }

  if (params.flow === 'consent_required') {
    return [
      `Halo, Anda mendapatkan undangan sesi dari ${params.clinicName}.`,
      scheduleLine,
      'Sebelum sesi dimulai, mohon lengkapi persetujuan data melalui link berikut:',
      params.registrationUrl ?? '-',
    ].join('\n');
  }

  return [
    `Halo, Anda mendapatkan undangan pendaftaran dari ${params.clinicName}.`,
    scheduleLine,
    'Sebelum sesi dimulai, mohon selesaikan registrasi melalui link berikut:',
    params.registrationUrl ?? '-',
  ].join('\n');
}

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

function isValidPhone(phone: string) {
  return /^[0-9+\-\s()]{7,20}$/.test(phone);
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
    case 'AUTH_REQUIRED': return 401;
    case 'FORBIDDEN': return 403;
    case 'INVALID_CLINIC':
    case 'INVALID_MEMBERSHIP':
    case 'INVALID_EMAIL':
    case 'INVALID_PHONE':
    case 'INVALID_SCHEDULE':
    case 'INVALID_DURATION':
    case 'NO_PRACTITIONER':
      return 400;
    default: return 500;
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

    const payload = (await req.json()) as CreateInvitationPayload;
    const clinicId = asTrimmedString(payload.clinic_id);
    const contactType = (asTrimmedString(payload.contact_type) || 'email') as ContactType;
    const recipientType = (asTrimmedString(payload.recipient_type) || 'client') as RecipientType;
    const email = asTrimmedString(payload.email).toLowerCase();
    const phone = asTrimmedString(payload.phone);
    const sessionDate = asTrimmedString(payload.session_date);
    const sessionTime = asTrimmedString(payload.session_time);
    const durationMinutes = asNumber(payload.duration_minutes);
    const recipientTimezone = resolveSessionTimezone(asTrimmedString(payload.recipient_timezone));
    const registrationBaseUrl = asTrimmedString(payload.registration_base_url);

    const skipEmail = contactType === 'phone' || recipientType === 'admin';

    if (!clinicId) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Klinik aktif tidak valid.' });
    }
    if (contactType === 'email' && !isValidEmail(email)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Email tidak valid.' });
    }
    if (contactType === 'phone' && !isValidPhone(phone)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Nomor HP tidak valid.' });
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
      .eq('clinic_id', clinicId)
      .eq('is_active', true)
      .order('is_owner', { ascending: false })
      .order('created_at', { ascending: true })
      .limit(1)
      .maybeSingle<{ id: string; clinic_id: string }>();

    if (!activeMembership) {
      return jsonResponse({ req, requestId, status: 403, success: false, code: 'FORBIDDEN', message: 'Membership klinik aktif tidak ditemukan.' });
    }

    const { data: clinicRow, error: clinicError } = await auth.supabase
      .from('clinics')
      .select('name')
      .eq('id', activeMembership.clinic_id)
      .maybeSingle<{ name: string | null }>();

    if (clinicError) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: `Gagal memuat nama klinik: ${clinicError.message}` });
    }

    const clinicName = asTrimmedString(clinicRow?.name) || 'Catatan Psikolog';

    const requestAuthClient = createRequestAuthClient(req);
    const { data: rpcData, error: rpcError } = await requestAuthClient.rpc('create_patient_invitation_with_schedule', {
      target_clinic_id: activeMembership.clinic_id,
      invited_by_membership_id: activeMembership.id,
      patient_email: contactType === 'email' ? email : null,
      patient_phone: contactType === 'phone' ? phone : null,
      contact_type: contactType,
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
        req, requestId,
        status: getStatusCodeFromInviteCode(rpcResult.code),
        success: false, code: 'BAD_REQUEST',
        message: rpcResult.message ?? 'Gagal membuat undangan.',
        data: { flow: rpcResult.flow ?? null },
      });
    }

    if (!rpcResult.invitationId) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'ID undangan tidak ditemukan dari server.' });
    }

    const registrationUrl = rpcResult.token
      ? `${registrationBaseUrl.replace(/\/$/, '')}/register?token=${encodeURIComponent(rpcResult.token)}`
      : null;

    const whatsappUrl =
      contactType === 'phone' && registrationUrl
        ? `https://wa.me/${encodeURIComponent(normalizeWhatsappTarget(phone))}?text=${encodeURIComponent(
            buildWhatsappInvitationMessage({
              clinicName,
              registrationUrl,
              flow: rpcResult.flow ?? null,
              sessionDate,
              sessionTime,
              timezone: recipientTimezone,
            }),
          )}`
        : null;

    const whatsappMessage =
      contactType === 'phone'
        ? buildWhatsappInvitationMessage({
            clinicName,
            registrationUrl,
            flow: rpcResult.flow ?? null,
            sessionDate,
            sessionTime,
            timezone: recipientTimezone,
          })
        : null;

    if (skipEmail) {
      return jsonResponse({
        req, requestId, status: 200, success: true, code: 'OK',
        message:
          contactType === 'phone'
            ? 'Undangan berhasil dibuat. WhatsApp akan dibuka dengan pesan siap kirim.'
            : 'Undangan berhasil dibuat. Salin link di bawah untuk dikirim ke pasien.',
        data: { flow: rpcResult.flow ?? null, registrationUrl, whatsappUrl, whatsappMessage },
      });
    }

    try {
      await sendPatientInvitationMail({
        supabase: auth.supabase,
        userId: auth.userId,
        requestId,
        invitationId: rpcResult.invitationId,
        registrationBaseUrl,
        recipientTimezone,
      });
    } catch (error) {
      const mailFailureReason = isMailDispatchError(error) ? error.reason : 'MAIL_DISPATCH_UNKNOWN';
      const mailFailureMessage = error instanceof Error ? error.message : 'unknown mail failure';
      console.error('[create-patient-invitation-v2][mail-fallback]', requestId, {
        invitationId: rpcResult.invitationId,
        flow: rpcResult.flow ?? null,
        reason: mailFailureReason,
        message: mailFailureMessage,
        details: isMailDispatchError(error) ? error.details ?? null : null,
      });
      const fallbackRegistrationUrl =
        rpcResult.flow === 'info_only' || !rpcResult.token ? null : registrationUrl;
      return jsonResponse({
        req, requestId, status: 200, success: true, code: 'OK',
        message:
          rpcResult.flow === 'info_only'
            ? 'Undangan tersimpan dan jadwal sesi sudah dibuat, tetapi email notifikasi gagal dikirim.'
            : 'Undangan tersimpan, tetapi pengiriman email gagal. Gunakan link fallback di bawah.',
        data: { flow: rpcResult.flow ?? null, mailFailureReason, fallbackRegistrationUrl },
      });
    }

    return jsonResponse({
      req, requestId, status: 200, success: true, code: 'OK',
      message:
        rpcResult.flow === 'registration_required'
          ? `Undangan registrasi berhasil dikirim ke ${email}.`
          : rpcResult.flow === 'consent_required'
            ? `Undangan persetujuan data berhasil dikirim ke ${email}.`
            : `Notifikasi jadwal berhasil dikirim ke ${email}.`,
      data: { flow: rpcResult.flow ?? null, fallbackRegistrationUrl: null },
    });
  } catch (error) {
    console.error('[create-patient-invitation-v2]', requestId, error);
    return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Terjadi kesalahan saat mengirim undangan.' });
  }
});
