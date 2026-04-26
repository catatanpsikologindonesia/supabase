export class MailFlowError extends Error {
  status: number;
  code: 'BAD_REQUEST' | 'FORBIDDEN';

  constructor(status: number, code: 'BAD_REQUEST' | 'FORBIDDEN', message: string) {
    super(message);
    this.name = 'MailFlowError';
    this.status = status;
    this.code = code;
  }
}

export function isMailFlowError(error: unknown): error is MailFlowError {
  return error instanceof MailFlowError;
}

export type MailFailureReason =
  | 'MAIL_ENV_MISSING'
  | 'MAIL_DISPATCH_TIMEOUT'
  | 'MAIL_DISPATCH_HTTP_ERROR'
  | 'MAIL_DISPATCH_INVALID_RESPONSE'
  | 'MAIL_DISPATCH_REJECTED'
  | 'MAIL_DISPATCH_UNKNOWN';

export class MailDispatchError extends Error {
  reason: MailFailureReason;
  details?: Record<string, unknown>;

  constructor(reason: MailFailureReason, message: string, details?: Record<string, unknown>) {
    super(message);
    this.name = 'MailDispatchError';
    this.reason = reason;
    this.details = details;
  }
}

export function isMailDispatchError(error: unknown): error is MailDispatchError {
  return error instanceof MailDispatchError;
}
