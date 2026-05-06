import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const BUCKET_NAME = 'patient_signatures';
const MAX_SIGNATURE_BYTES = 512 * 1024;
const PNG_SIGNATURE_HEADER = [0x89, 0x50, 0x4e, 0x47];

type ServiceRoleClient = ReturnType<typeof createServiceRoleClient>;

export function createServiceRoleClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim() ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ?? '';

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not configured.');
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function decodeBase64Payload(base64DataUrl: string) {
  if (!base64DataUrl.startsWith('data:image/png;base64,')) {
    throw new Error('Format tanda tangan tidak valid.');
  }

  const encoded = base64DataUrl.replace('data:image/png;base64,', '');
  const binary = atob(encoded);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));

  if (bytes.byteLength === 0 || bytes.byteLength > MAX_SIGNATURE_BYTES) {
    throw new Error('Ukuran tanda tangan tidak valid.');
  }

  for (let index = 0; index < PNG_SIGNATURE_HEADER.length; index += 1) {
    if (bytes[index] !== PNG_SIGNATURE_HEADER[index]) {
      throw new Error('Format tanda tangan tidak valid.');
    }
  }

  return bytes;
}

async function resolveExistingSignature(serviceRole: ServiceRoleClient, patientId: string) {
  const { data, error } = await serviceRole
    .from('patient_signatures')
    .select('id, storage_path')
    .eq('patient_id', patientId)
    .maybeSingle();

  if (error) {
    throw new Error(`Gagal memeriksa tanda tangan yang sudah ada: ${error.message}`);
  }

  return data as { id: string; storage_path: string } | null;
}

export async function createOrReusePatientSignature(params: {
  serviceRole: ServiceRoleClient;
  patientId: string;
  signatureDataUrl: string;
  signedByName: string;
  signedIp: string | null;
  signedUserAgent: string | null;
}) {
  const existing = await resolveExistingSignature(params.serviceRole, params.patientId);
  if (existing) return existing.id;

  const bytes = decodeBase64Payload(params.signatureDataUrl);
  const storagePath = `${params.patientId}/signature.png`;

  const { error: uploadError } = await params.serviceRole.storage
    .from(BUCKET_NAME)
    .upload(storagePath, bytes, {
      contentType: 'image/png',
      upsert: false,
    });

  if (uploadError && !uploadError.message.toLowerCase().includes('already exists')) {
    throw new Error(`Gagal mengunggah tanda tangan: ${uploadError.message}`);
  }

  const { data: insertData, error: insertError } = await params.serviceRole
    .from('patient_signatures')
    .insert({
      patient_id: params.patientId,
      storage_bucket: BUCKET_NAME,
      storage_path: storagePath,
      signed_by_name: params.signedByName,
      signed_ip: params.signedIp,
      signed_user_agent: params.signedUserAgent,
    })
    .select('id')
    .single();

  if (insertError) {
    if (insertError.code === '23505') {
      const row = await resolveExistingSignature(params.serviceRole, params.patientId);
      if (row) return row.id;
    }
    throw new Error(`Gagal menyimpan metadata tanda tangan: ${insertError.message}`);
  }

  return insertData.id as string;
}
