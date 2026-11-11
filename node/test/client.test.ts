import { describe, expect, it } from 'vitest';
import { APIConnectionError, APIError, APITimeoutError, Noosh24, RateLimitError, TemporarilyUnavailableError, VERSION, buildQuery } from '../src/index.js';
import { setup } from './helpers.js';

describe('client', () => {
  it('sends the key and headers to the default base URL', async () => {
    const { client, http } = setup();
    http.json(200, {
      data: {
        restaurant: { id: 'r1', name: 'Masago', slug: 'masago' },
        key: { id: 'k1', name: 'Wolt', prefix: 'nsk_Ab3dE9xQ', scopes: ['menu:read'] },
        subscription: { status: 'active', modules: ['loyalty'] },
        features: { loyalty: true, inventory: false },
      },
    });

    const me = await client.whoami();

    expect(http.last.method).toBe('GET');
    expect(http.last.url).toBe('https://open-api.noosh24.com/v1/whoami');
    expect(http.last.headers.Authorization).toBe('Bearer nsk_test_123');
    expect(http.last.headers.Accept).toBe('application/json');
    expect(http.last.headers['User-Agent']).toBe(`noosh24-node/${VERSION}`);
    expect(http.last.body).toBeUndefined();
    expect(me.restaurant.name).toBe('Masago');
    expect(me.features.inventory).toBe(false);
  });

  it('takes a custom base URL and user agent', async () => {
    const { client, http } = setup({ baseUrl: 'http://localhost:8080/v1/', userAgent: 'acme-pos/2.1' });
    http.json(200, { data: {} });

    await client.whoami();

    expect(http.last.url).toBe('http://localhost:8080/v1/whoami');
    expect(http.last.headers['User-Agent']).toBe(`acme-pos/2.1 noosh24-node/${VERSION}`);
  });

  it('rejects an empty key', () => {
    expect(() => new Noosh24('  ')).toThrow(TypeError);
  });

  it('retries a rate limit after Retry-After', async () => {
    const { client, http, sleeps } = setup();
    http.json(429, { error: 'rate_limit_exceeded', message: 'slow down' }, { 'Retry-After': '3' }).json(200, { data: { items: [], total: 0 } });

    expect(await client.tables.list()).toEqual([]);
    expect(http.calls).toHaveLength(2);
    expect(sleeps).toEqual([3000]);
  });

  it('gives up after maxRetries', async () => {
    const { client, http } = setup({ maxRetries: 1 });
    http
      .json(429, { error: 'rate_limit_exceeded', message: 'slow down' }, { 'Retry-After': '1' })
      .json(429, { error: 'rate_limit_exceeded', message: 'slow down' }, { 'Retry-After': '7' });

    const error = await client.tables.list().catch((e: unknown) => e);

    expect(error).toBeInstanceOf(RateLimitError);
    const rate = error as RateLimitError;
    expect(rate.status).toBe(429);
    expect(rate.code).toBe('rate_limit_exceeded');
    expect(rate.retryAfter).toBe(7);
    expect(rate.message).toBe('slow down');
    expect(rate.name).toBe('RateLimitError');
    expect(http.calls).toHaveLength(2);
  });

  it('does not wait longer than a minute', async () => {
    const { client, http, sleeps } = setup();
    http.json(429, { error: 'rate_limit_exceeded' }, { 'Retry-After': '120' });

    await expect(client.tables.list()).rejects.toBeInstanceOf(RateLimitError);
    expect(http.calls).toHaveLength(1);
    expect(sleeps).toEqual([]);
  });

  it('backs off on temporarily_unavailable', async () => {
    const { client, http, sleeps } = setup();
    for (let i = 0; i < 3; i++) http.json(503, { error: 'temporarily_unavailable', message: 'try again' });

    await expect(client.tables.listHalls()).rejects.toBeInstanceOf(TemporarilyUnavailableError);
    expect(http.calls).toHaveLength(3);
    expect(sleeps).toEqual([500, 1000]);
  });

  it('retries connection errors on reads and wraps them', async () => {
    const { client, http } = setup({ maxRetries: 1 });
    http.fail(new Error('ECONNRESET')).json(200, { data: { items: [{ id: 'h1', name: 'Main', position: 1 }], total: 1 } });

    const halls = await client.tables.listHalls();
    expect(halls[0].name).toBe('Main');

    http.fail(new Error('ECONNRESET')).fail(new Error('ECONNRESET'));
    const error = await client.tables.listHalls().catch((e: unknown) => e);
    expect(error).toBeInstanceOf(APIConnectionError);
    expect((error as Error).message).toContain('ECONNRESET');
  });

  it('times out', async () => {
    const client = new Noosh24('nsk_x', {
      timeout: 20,
      maxRetries: 0,
      fetch: (_url, init) =>
        new Promise((_resolve, reject) => {
          init.signal?.addEventListener('abort', () => reject(new Error('aborted')));
        }),
    });

    await expect(client.whoami()).rejects.toBeInstanceOf(APITimeoutError);
  });

  it('treats a body that is not JSON as an API error', async () => {
    const { client, http } = setup();
    http.raw(200, '<html>gateway</html>');

    await expect(client.whoami()).rejects.toBeInstanceOf(APIError);
  });

  it('builds repeated query parameters', () => {
    expect(buildQuery({ sort: ['price desc', 'name asc'], where: "category = 'Salads'", skip: undefined, available: true })).toBe(
      'sort=price%20desc&sort=name%20asc&where=category%20%3D%20%27Salads%27&available=true',
    );
  });
});
