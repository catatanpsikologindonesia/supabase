function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function generateOtpCode(): string {
  const random = new Uint32Array(1);
  crypto.getRandomValues(random);
  const code = 100000 + (random[0] % 900000);
  return String(code);
}

export async function hashOtpCode(otp: string): Promise<string> {
  const data = new TextEncoder().encode(otp);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return bytesToHex(new Uint8Array(digest));
}
