export class Noosh24Error extends Error {
  constructor(message: string, options?: { cause?: unknown }) {
    super(message);
    this.name = new.target.name;
    if (options && 'cause' in options) {
      Object.defineProperty(this, 'cause', { value: options.cause, enumerable: false, writable: true, configurable: true });
    }
  }
}

export class APIConnectionError extends Noosh24Error {}

export class APITimeoutError extends APIConnectionError {}

export class APIError extends Noosh24Error {
  readonly status: number;
  readonly code: string | null;
  readonly headers: Record<string, string>;
  readonly body: string;

  constructor(status: number, code: string | null, message: string, headers: Record<string, string> = {}, body = '') {
    super(message);
    this.status = status;
    this.code = code;
    this.headers = headers;
    this.body = body;
  }
}

export class ValidationError extends APIError {}
export class AuthenticationError extends APIError {}
export class NoApiKeyError extends AuthenticationError {}
export class InvalidApiKeyError extends AuthenticationError {}
export class PermissionDeniedError extends APIError {}
export class InsufficientScopeError extends PermissionDeniedError {}
export class ModuleNotEnabledError extends PermissionDeniedError {}
export class VenueSuspendedError extends PermissionDeniedError {}
export class NotYourReservationError extends PermissionDeniedError {}
export class NotFoundError extends APIError {}
export class TableNotFoundError extends NotFoundError {}
export class ConflictError extends APIError {}
export class TableTakenError extends ConflictError {}
export class CannotCancelError extends ConflictError {}
export class UnprocessableError extends APIError {}
export class OutsideHoursError extends UnprocessableError {}
export class InThePastError extends UnprocessableError {}
export class TableTooSmallError extends UnprocessableError {}
export class ServerError extends APIError {}
export class TemporarilyUnavailableError extends ServerError {}

export class RateLimitError extends APIError {
  get retryAfter(): number | null {
    const value = this.headers['retry-after'];
    if (value === undefined || value.trim() === '' || !Number.isFinite(Number(value))) {
      return null;
    }
    return Math.max(0, Math.trunc(Number(value)));
  }
}

type APIErrorClass = new (status: number, code: string | null, message: string, headers?: Record<string, string>, body?: string) => APIError;

const byCode: Record<string, APIErrorClass> = {
  validation_error: ValidationError,
  no_api_key: NoApiKeyError,
  invalid_api_key: InvalidApiKeyError,
  insufficient_scope: InsufficientScopeError,
  module_not_enabled: ModuleNotEnabledError,
  venue_suspended: VenueSuspendedError,
  not_your_reservation: NotYourReservationError,
  not_found: NotFoundError,
  table_not_found: TableNotFoundError,
  table_taken: TableTakenError,
  cannot_cancel: CannotCancelError,
  outside_hours: OutsideHoursError,
  in_the_past: InThePastError,
  table_too_small: TableTooSmallError,
  rate_limit_exceeded: RateLimitError,
  temporarily_unavailable: TemporarilyUnavailableError,
};

const byStatus: Record<number, APIErrorClass> = {
  400: ValidationError,
  401: AuthenticationError,
  403: PermissionDeniedError,
  404: NotFoundError,
  409: ConflictError,
  422: UnprocessableError,
  429: RateLimitError,
};

export function errorFromResponse(status: number, headers: Record<string, string>, body: string): APIError {
  let code: string | null = null;
  let message = '';
  try {
    const parsed: unknown = JSON.parse(body);
    if (parsed && typeof parsed === 'object') {
      const record = parsed as Record<string, unknown>;
      if (typeof record.error === 'string') code = record.error;
      if (typeof record.message === 'string') message = record.message;
    }
  } catch {
  }
  if (message === '') {
    message = code ?? `HTTP ${status}`;
  }
  const ErrorClass =
    (code !== null && Object.prototype.hasOwnProperty.call(byCode, code) ? byCode[code] : undefined) ??
    byStatus[status] ??
    (status >= 500 ? ServerError : APIError);
  return new ErrorClass(status, code, message, headers, body);
}
