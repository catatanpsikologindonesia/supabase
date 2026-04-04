const MAIL_DISPATCHER_TIMEOUT_MS = 10_000;

export type DispatchMailInput = {
  requestId?: string;
  to: string;
  subject: string;
  html: string;
  replyTo?: string;
  useCustomFrom?: boolean;
};

type MailDispatcherResponse = {
  success?: boolean;
  code?: string;
  message?: string;
  request_id?: string;
  http_status?: number;
};

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim() ?? '';
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function toHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function computeSignature(secret: string, signingString: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(signingString));
  return toHex(signature);
}

function buildSigningString(
  timestamp: string,
  requestId: string,
  to: string,
  subject: string,
  html: string,
  replyTo: string,
  useCustomFrom: boolean,
): string {
  return [timestamp, requestId, to, subject, html, replyTo, useCustomFrom ? '1' : '0'].join('\n');
}

export async function dispatchMail(input: DispatchMailInput): Promise<void> {
  const webhookUrl = requireEnv('MAIL_DISPATCHER_WEBHOOK_URL');
  const secret = requireEnv('MAIL_WEBHOOK_SECRET');

  const requestId = input.requestId?.trim() || crypto.randomUUID();
  const timestamp = new Date().toISOString();
  const payloadBase = {
    timestamp,
    request_id: requestId,
    to: input.to.trim(),
    subject: input.subject.trim(),
    html: input.html,
    reply_to: input.replyTo?.trim() || '',
    use_custom_from: input.useCustomFrom !== false,
  };

  const signature = await computeSignature(
    secret,
    buildSigningString(
      payloadBase.timestamp,
      payloadBase.request_id,
      payloadBase.to,
      payloadBase.subject,
      payloadBase.html,
      payloadBase.reply_to,
      payloadBase.use_custom_from,
    ),
  );

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), MAIL_DISPATCHER_TIMEOUT_MS);

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ...payloadBase,
        signature,
      }),
      signal: controller.signal,
    });

    const responseText = await response.text();
    let parsed: MailDispatcherResponse | null = null;

    try {
      parsed = responseText ? (JSON.parse(responseText) as MailDispatcherResponse) : null;
    } catch {
      throw new Error('mail dispatcher returned non-JSON response');
    }

    if (!response.ok || !parsed?.success) {
      throw new Error(parsed?.message?.trim() || 'mail dispatcher rejected request');
    }
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new Error('mail dispatcher request timed out');
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}
