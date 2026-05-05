export function asString(value: unknown): string {
  if (typeof value === 'string') return value.trim();
  if (value == null) return '';

  try {
    return JSON.stringify(value).trim();
  } catch {
    return String(value).trim();
  }
}

export function nullableText(value: unknown): string | null {
  const text = asString(value);
  return text === '' ? null : text;
}

export function asBool(value: unknown): boolean {
  if (value === true || value === 1) return true;
  if (typeof value === 'string') {
    return ['true', '1', 'yes', 'on'].includes(value.trim().toLowerCase());
  }
  return false;
}

export function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export function isValidProfession(value: string): boolean {
  return ['psychologist', 'counselor', 'other'].includes(value);
}
