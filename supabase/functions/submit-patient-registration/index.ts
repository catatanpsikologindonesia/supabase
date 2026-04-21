import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { z } from 'https://esm.sh/zod@3.23.8';
import { jsonResponse, preflight, requestIdFrom } from '../_shared/http.ts';

type RegistrationRpcResponse = {
  status: 'success' | 'error';
  code?: string;
  message?: string;
};

type InvitationLookup = {
  email: string;
  expires_at: string;
  is_used: boolean;
  flow: 'registration_required' | 'consent_required' | 'info_only';
  used_reason:
    | 'registration_completed'
    | 'consent_accepted'
    | 'info_only_notified'
    | 'superseded'
    | 'expired'
    | 'cancelled'
    | null;
};

const optionalText = z.string().trim().transform((value) => (value === '' ? undefined : value)).optional();
const optionalNumber = z
  .union([z.string(), z.number()])
  .transform((value) => {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : undefined;
    }
    const trimmed = value.trim();
    return trimmed === '' ? undefined : Number(trimmed);
  })
  .refine((value) => value === undefined || Number.isFinite(value), 'Input angka tidak valid.')
  .optional();

const patientIntakeSchema = z.object({
  email: z.string().trim().email('Email tidak valid.'),
  fullName: z.string().trim().min(2, 'Nama lengkap wajib diisi.'),
  birthDate: z.string().trim().regex(/^\d{4}-\d{2}-\d{2}$/, 'Tanggal lahir wajib diisi dengan format valid.'),
  sex: z.enum(['L', 'P']),
  phone: optionalText,
  religion: optionalText,
  education: optionalText,
  occupation: optionalText,
  hobby: optionalText,
  address: optionalText,
  guardianName: optionalText,
  guardianRelation: optionalText,
  guardianPhone: optionalText,
  guardianAddress: optionalText,
  fatherName: optionalText,
  fatherAge: optionalNumber,
  fatherEducation: optionalText,
  fatherOccupation: optionalText,
  motherName: optionalText,
  motherAge: optionalNumber,
  motherEducation: optionalText,
  motherOccupation: optionalText,
  maritalStatus: optionalText,
  numberOfChildren: optionalNumber,
  monthlyIncome: optionalNumber,
  familyNotes: optionalText,
  motherPregnancyNotes: optionalText,
  birthProcess: z.enum(['normal', 'sc', 'assisted']).optional(),
  gestationalAgeWeeks: optionalNumber,
  birthWeightKg: optionalNumber,
  birthLengthCm: optionalNumber,
  walkingAgeMonths: optionalNumber,
  speakingAgeMonths: optionalNumber,
  hearingFunction: optionalText,
  speechArticulation: optionalText,
  visionFunction: optionalText,
  childMedicalHistory: optionalText,
  specialNotes: optionalText,
  knowsLetters: z.boolean().default(false),
  knowsColors: z.boolean().default(false),
  writes: z.boolean().default(false),
  counts: z.boolean().default(false),
  reads: z.boolean().default(false),
  readingSpelling: z.boolean().default(false),
  fluentReading: z.boolean().default(false),
  reversedLetters: z.boolean().default(false),
  autismIndication: z.enum(['high_risk', 'low_risk', 'other_disorder', 'borderline_normal']).optional(),
  adhdIndication: z.enum(['possible_adhd', 'not_adhd']).optional(),
  initialConclusion: optionalText,
  interventionCounselingGiven: z.boolean().default(false),
  interventionAreas: optionalText,
  otherMedicalAction: optionalText,
  referralAction: optionalText,
  assessmentResult: optionalText,
  agreeToDataSharing: z.boolean().refine((value) => value, {
    message: 'Persetujuan berbagi data wajib disetujui.',
  }),
});

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

  throw new Error('Missing anon/publishable key for public edge client.');
}

function createPublicClient(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  if (!supabaseUrl) {
    throw new Error('SUPABASE_URL is not configured.');
  }

  return createClient(supabaseUrl, resolvePublicAnonKey(req), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function getStatusCodeFromRegistrationCode(code?: string) {
  switch (code) {
    case 'INVALID_TOKEN':
    case 'INVALID_PAYLOAD':
    case 'AUTH_USER_REQUIRED':
    case 'AUTH_EMAIL_REQUIRED':
    case 'AUTH_USER_NOT_FOUND':
    case 'EMAIL_MISMATCH':
    case 'INVITATION_CLINIC_REQUIRED':
    case 'INVALID_FLOW':
    case 'CONSENT_REQUIRED':
      return 400;
    case 'INVITATION_NOT_FOUND':
    case 'PATIENT_NOT_FOUND':
      return 404;
    case 'INVITATION_USED':
    case 'INVITATION_SUPERSEDED':
      return 409;
    case 'INVITATION_EXPIRED':
      return 410;
    case 'NO_PSYCHOLOGIST':
    case 'NO_PRACTITIONER':
      return 400;
    default:
      return 500;
  }
}

function isAlreadyRegisteredError(message: string) {
  const normalized = message.toLowerCase();
  return normalized.includes('already registered') || normalized.includes('already exists') || normalized.includes('user exists');
}

function isInvalidCredentialError(message: string) {
  const normalized = message.toLowerCase();
  return normalized.includes('invalid login credentials') || normalized.includes('invalid credentials');
}

function buildDefaultPasswordFromBirthDate(birthDate: string) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(birthDate.trim());
  if (!match) return null;
  const [, year, month, day] = match;
  return `${day}${month}${year}`;
}

function getRequestIp(req: Request) {
  return req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? req.headers.get('x-real-ip')?.trim() ?? null;
}

Deno.serve(async (req) => {
  const preflightResp = preflight(req);
  if (preflightResp) return preflightResp;

  const requestId = requestIdFrom(req);
  if (req.method !== 'POST') {
    return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: 'Method tidak didukung.' });
  }

  try {
    const body = (await req.json()) as { token?: unknown; payload?: unknown };
    const token = String(body.token ?? '').trim();

    if (!token) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'INVALID_TOKEN', message: 'Token registrasi tidak valid.' });
    }

    const payloadParsed = patientIntakeSchema.safeParse(body.payload);
    if (!payloadParsed.success) {
      return jsonResponse({
        req,
        requestId,
        status: 400,
        success: false,
        code: 'INVALID_PAYLOAD',
        message: payloadParsed.error.issues[0]?.message ?? 'Data form tidak valid.',
      });
    }

    const supabase = createPublicClient(req);

    const { data: invitation, error: invitationError } = await supabase
      .rpc('get_invitation_by_token', { invite_token: token })
      .maybeSingle<InvitationLookup>();

    if (invitationError) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Gagal memverifikasi token registrasi.' });
    }
    if (!invitation) {
      return jsonResponse({ req, requestId, status: 404, success: false, code: 'INVITATION_NOT_FOUND', message: 'Undangan tidak ditemukan. Silakan minta link baru.' });
    }
    if (invitation.is_used) {
      return jsonResponse({
        req,
        requestId,
        status: 409,
        success: false,
        code: invitation.used_reason === 'superseded' ? 'INVITATION_SUPERSEDED' : 'INVITATION_USED',
        message:
          invitation.used_reason === 'superseded'
            ? 'Link undangan ini sudah diganti dengan undangan terbaru.'
            : 'Link registrasi sudah digunakan.',
      });
    }
    if (new Date(invitation.expires_at) < new Date()) {
      return jsonResponse({ req, requestId, status: 410, success: false, code: 'INVITATION_EXPIRED', message: 'Link registrasi sudah kedaluwarsa.' });
    }
    if (invitation.flow !== 'registration_required') {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'INVALID_FLOW', message: 'Undangan ini tidak membutuhkan registrasi penuh.' });
    }

    const invitationEmail = invitation.email.trim().toLowerCase();
    const payloadEmail = payloadParsed.data.email.trim().toLowerCase();
    if (payloadEmail !== invitationEmail) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'EMAIL_MISMATCH', message: 'Email registrasi tidak sesuai dengan email undangan.' });
    }

    const password = buildDefaultPasswordFromBirthDate(payloadParsed.data.birthDate);
    if (!password) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'INVALID_PAYLOAD', message: 'Tanggal lahir tidak valid untuk membuat password default.' });
    }

    let authUserId: string | null = null;
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email: invitationEmail,
      password,
      options: {
        data: { role: 'patient' },
      },
    });

    if (signUpError && !isAlreadyRegisteredError(signUpError.message)) {
      return jsonResponse({ req, requestId, status: 400, success: false, code: 'BAD_REQUEST', message: `Gagal membuat akun login: ${signUpError.message}` });
    }

    authUserId = signUpData.user?.id ?? null;
    if (!authUserId) {
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
        email: invitationEmail,
        password,
      });

      if (signInError) {
        return jsonResponse({
          req,
          requestId,
          status: isInvalidCredentialError(signInError.message) ? 409 : 400,
          success: false,
          code: 'BAD_REQUEST',
          message: isInvalidCredentialError(signInError.message)
            ? 'Email ini sudah terdaftar dengan password yang berbeda dari format tanggal lahir. Silakan reset password.'
            : `Gagal memverifikasi akun login: ${signInError.message}`,
        });
      }

      authUserId = signInData.user?.id ?? null;
    }

    if (!authUserId) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Akun login tidak berhasil dibuat. Coba lagi beberapa saat.' });
    }

    const { data: createData, error: createError } = await supabase.rpc('create_patient_from_auth_user', {
      invite_token: token,
      auth_user_id: authUserId,
      auth_email: invitationEmail,
    });

    if (createError) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: `Gagal menyiapkan data pasien: ${createError.message}` });
    }

    const createResult = (createData ?? null) as RegistrationRpcResponse | null;
    if (!createResult) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Gagal menyiapkan data pasien karena response server kosong.' });
    }
    if (createResult.status === 'error') {
      return jsonResponse({
        req,
        requestId,
        status: getStatusCodeFromRegistrationCode(createResult.code),
        success: false,
        code: 'BAD_REQUEST',
        message: createResult.message ?? 'Gagal menyiapkan data pasien.',
      });
    }

    const registrationPayload = { ...payloadParsed.data } as Record<string, unknown>;
    delete registrationPayload.email;
    registrationPayload._consentIp = getRequestIp(req);
    registrationPayload._consentUserAgent = req.headers.get('user-agent') ?? null;

    const { data, error } = await supabase.rpc('update_patient_registration_by_user_id', {
      invite_token: token,
      target_user_id: authUserId,
      registration_payload: registrationPayload,
    });

    if (error) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: `Gagal memproses registrasi: ${error.message}` });
    }

    const result = (data ?? null) as RegistrationRpcResponse | null;
    if (!result) {
      return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Registrasi gagal diproses karena response server kosong.' });
    }

    if (result.status === 'error') {
      return jsonResponse({
        req,
        requestId,
        status: getStatusCodeFromRegistrationCode(result.code),
        success: false,
        code: 'BAD_REQUEST',
        message: result.message ?? 'Registrasi gagal diproses.',
      });
    }

    return jsonResponse({
      req,
      requestId,
      status: 200,
      success: true,
      code: 'OK',
      message: result.message ?? 'Registrasi berhasil. Tim psikolog akan menghubungi Anda untuk sesi lanjutan.',
    });
  } catch (error) {
    console.error('[submit-patient-registration]', requestId, error);
    return jsonResponse({ req, requestId, status: 500, success: false, code: 'INTERNAL_ERROR', message: 'Terjadi kesalahan saat memproses registrasi.' });
  }
});
