import { describe, expect, it } from 'vitest';
import * as sdk from '../src/index.js';
import { setup } from './helpers.js';

const cases: [number, string | null, new (...args: never[]) => sdk.APIError, new (...args: never[]) => Error][] = [
  [400, 'validation_error', sdk.ValidationError, sdk.APIError],
  [401, 'no_api_key', sdk.NoApiKeyError, sdk.AuthenticationError],
  [401, 'invalid_api_key', sdk.InvalidApiKeyError, sdk.AuthenticationError],
  [403, 'insufficient_scope', sdk.InsufficientScopeError, sdk.PermissionDeniedError],
  [403, 'module_not_enabled', sdk.ModuleNotEnabledError, sdk.PermissionDeniedError],
  [403, 'venue_suspended', sdk.VenueSuspendedError, sdk.PermissionDeniedError],
  [403, 'not_your_reservation', sdk.NotYourReservationError, sdk.PermissionDeniedError],
  [404, 'not_found', sdk.NotFoundError, sdk.APIError],
  [404, 'table_not_found', sdk.TableNotFoundError, sdk.NotFoundError],
  [409, 'table_taken', sdk.TableTakenError, sdk.ConflictError],
  [409, 'cannot_cancel', sdk.CannotCancelError, sdk.ConflictError],
  [422, 'outside_hours', sdk.OutsideHoursError, sdk.UnprocessableError],
  [422, 'in_the_past', sdk.InThePastError, sdk.UnprocessableError],
  [422, 'table_too_small', sdk.TableTooSmallError, sdk.UnprocessableError],
  [429, 'rate_limit_exceeded', sdk.RateLimitError, sdk.APIError],
  [503, 'temporarily_unavailable', sdk.TemporarilyUnavailableError, sdk.ServerError],
  [403, 'something_new', sdk.PermissionDeniedError, sdk.APIError],
  [409, 'something_new', sdk.ConflictError, sdk.APIError],
  [500, 'query_failed', sdk.ServerError, sdk.APIError],
  [418, null, sdk.APIError, sdk.Noosh24Error],
];

describe('errors', () => {
  it.each(cases)('maps %i %s', async (status, code, ErrorClass, Parent) => {
    const { client, http } = setup({ maxRetries: 0 });
    http.json(status, code === null ? { nope: true } : { error: code, message: 'Mesaj' });

    const error = (await client.customers.get('c1').catch((e: unknown) => e)) as sdk.APIError;

    expect(error.constructor).toBe(ErrorClass);
    expect(error).toBeInstanceOf(Parent);
    expect(error).toBeInstanceOf(sdk.Noosh24Error);
    expect(error).toBeInstanceOf(Error);
    expect(error.status).toBe(status);
    expect(error.code).toBe(code);
    expect(error.message).toBe(code === null ? `HTTP ${status}` : 'Mesaj');
    expect(error.name).toBe(ErrorClass.name);
  });

  it('does not retry a validation error', async () => {
    const { client, http } = setup();
    http.json(400, { error: 'validation_error', message: '"nope" is not a filterable field on this resource' });

    await expect(client.menu.listProducts({ where: 'nope = 1' })).rejects.toThrow('"nope" is not a filterable field on this resource');
    expect(http.calls).toHaveLength(1);
  });
});
