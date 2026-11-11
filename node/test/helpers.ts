import { Noosh24, type ClientOptions } from '../src/index.js';

export interface Call {
  url: string;
  method: string;
  headers: Record<string, string>;
  body: string | undefined;
}

type Queued = { status: number; body: unknown; headers?: Record<string, string>; raw?: boolean } | Error;

export class MockFetch {
  readonly calls: Call[] = [];
  private readonly queue: Queued[] = [];

  json(status: number, body: unknown, headers: Record<string, string> = {}): this {
    this.queue.push({ status, body, headers });
    return this;
  }

  raw(status: number, body: string): this {
    this.queue.push({ status, body, raw: true });
    return this;
  }

  fail(error: Error): this {
    this.queue.push(error);
    return this;
  }

  readonly fetch = async (url: string, init: RequestInit): Promise<Response> => {
    this.calls.push({
      url,
      method: String(init.method),
      headers: { ...(init.headers as Record<string, string>) },
      body: init.body === undefined ? undefined : String(init.body),
    });
    const next = this.queue.shift();
    if (next === undefined) {
      throw new Error(`No response queued for ${init.method} ${url}`);
    }
    if (next instanceof Error) {
      throw next;
    }
    const text = next.raw ? String(next.body) : JSON.stringify(next.body);
    return new Response(text, { status: next.status, headers: { 'content-type': 'application/json', ...next.headers } });
  };

  get last(): Call {
    return this.calls[this.calls.length - 1];
  }
}

export function query(call: Call): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  new URL(call.url).searchParams.forEach((value, name) => {
    (out[name] ??= []).push(value);
  });
  return out;
}

export function setup(options: ClientOptions = {}) {
  const http = new MockFetch();
  const sleeps: number[] = [];
  const client = new Noosh24('nsk_test_123', {
    fetch: http.fetch,
    sleep: async (ms) => {
      sleeps.push(ms);
    },
    ...options,
  });
  return { client, http, sleeps };
}

export function page<T>(items: T[], total: number, limit = 20, offset = 0) {
  return { data: { items, total, limit, offset } };
}
