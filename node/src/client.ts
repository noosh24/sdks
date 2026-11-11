import { APIConnectionError, APIError, APITimeoutError, errorFromResponse } from './errors.js';
import type { Whoami } from './models.js';
import { Customers } from './resources/customers.js';
import { Loyalty } from './resources/loyalty.js';
import { Menu } from './resources/menu.js';
import { Orders } from './resources/orders.js';
import { Payments } from './resources/payments.js';
import { Reservations } from './resources/reservations.js';
import { Reviews } from './resources/reviews.js';
import { Stock } from './resources/stock.js';
import { Tables } from './resources/tables.js';
import { VERSION } from './version.js';

export const DEFAULT_BASE_URL = 'https://open-api.noosh24.com/v1';

export type FetchLike = (input: string, init: RequestInit) => Promise<Response>;

export interface ClientOptions {
  baseUrl?: string;
  timeout?: number;
  maxRetries?: number;
  userAgent?: string;
  fetch?: FetchLike;
  sleep?: (ms: number) => Promise<void>;
}

export type QueryValue = string | number | boolean | null | undefined | readonly (string | number | boolean)[];

export interface RequestOptions {
  query?: Record<string, QueryValue>;
  body?: unknown;
  retryable?: boolean;
}

export interface RawResponse<T> {
  status: number;
  data: T;
}

const RETRY_STATUSES = new Set([429, 502, 503, 504]);
const MAX_RETRY_WAIT_MS = 60_000;

export class Noosh24 {
  readonly menu: Menu;
  readonly reservations: Reservations;
  readonly orders: Orders;
  readonly payments: Payments;
  readonly tables: Tables;
  readonly customers: Customers;
  readonly loyalty: Loyalty;
  readonly stock: Stock;
  readonly reviews: Reviews;

  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly timeout: number;
  private readonly maxRetries: number;
  private readonly userAgent: string;
  private readonly fetchImpl: FetchLike;
  private readonly sleep: (ms: number) => Promise<void>;

  constructor(apiKey: string, options: ClientOptions = {}) {
    const key = (apiKey ?? '').trim();
    if (key === '') {
      throw new TypeError('An API key is required');
    }
    this.apiKey = key;
    this.baseUrl = (options.baseUrl ?? DEFAULT_BASE_URL).replace(/\/+$/, '');
    this.timeout = options.timeout ?? 30_000;
    this.maxRetries = Math.max(0, Math.trunc(options.maxRetries ?? 2));
    const agent = `noosh24-node/${VERSION}`;
    this.userAgent = options.userAgent ? `${options.userAgent} ${agent}` : agent;
    const fetchImpl = options.fetch ?? (globalThis.fetch as FetchLike | undefined);
    if (!fetchImpl) {
      throw new TypeError('No fetch implementation found: use Node.js 18+ or pass options.fetch');
    }
    this.fetchImpl = fetchImpl;
    this.sleep = options.sleep ?? ((ms) => new Promise((resolve) => setTimeout(resolve, ms)));

    this.menu = new Menu(this);
    this.reservations = new Reservations(this);
    this.orders = new Orders(this);
    this.payments = new Payments(this);
    this.tables = new Tables(this);
    this.customers = new Customers(this);
    this.loyalty = new Loyalty(this);
    this.stock = new Stock(this);
    this.reviews = new Reviews(this);
  }

  async whoami(): Promise<Whoami> {
    return (await this.request<Whoami>('GET', '/whoami')).data;
  }

  async request<T>(method: string, path: string, options: RequestOptions = {}): Promise<RawResponse<T>> {
    const query = buildQuery(options.query ?? {});
    const url = `${this.baseUrl}${path}${query ? `?${query}` : ''}`;
    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.apiKey}`,
      Accept: 'application/json',
      'User-Agent': this.userAgent,
    };
    let body: string | undefined;
    if (options.body !== undefined) {
      headers['Content-Type'] = 'application/json';
      body = JSON.stringify(options.body);
    }
    const retryable = options.retryable ?? true;

    for (let attempt = 0; ; attempt++) {
      let response: Response;
      try {
        response = await this.send(url, { method, headers, body });
      } catch (error) {
        if (!retryable || attempt >= this.maxRetries) {
          throw error;
        }
        await this.sleep(backoff(attempt));
        continue;
      }
      const text = await response.text();
      const responseHeaders = headersToRecord(response.headers);
      if (response.status >= 200 && response.status < 300) {
        return { status: response.status, data: decode<T>(response.status, responseHeaders, text) };
      }
      const wait = retryWait(response.status, responseHeaders, attempt);
      if (retryable && attempt < this.maxRetries && wait !== null) {
        await this.sleep(wait);
        continue;
      }
      throw errorFromResponse(response.status, responseHeaders, text);
    }
  }

  private async send(url: string, init: RequestInit): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeout);
    try {
      return await this.fetchImpl(url, { ...init, signal: controller.signal });
    } catch (error) {
      if (controller.signal.aborted) {
        throw new APITimeoutError(`Request timed out after ${this.timeout} ms`, { cause: error });
      }
      const message = error instanceof Error ? error.message : String(error);
      throw new APIConnectionError(`Could not reach the Noosh24 API: ${message}`, { cause: error });
    } finally {
      clearTimeout(timer);
    }
  }
}

export function buildQuery(query: Record<string, QueryValue>): string {
  const params = new URLSearchParams();
  for (const [name, value] of Object.entries(query)) {
    if (value === null || value === undefined) continue;
    const values = Array.isArray(value) ? value : [value];
    for (const item of values) {
      params.append(name, String(item));
    }
  }
  return params.toString().replace(/\+/g, '%20');
}

function decode<T>(status: number, headers: Record<string, string>, text: string): T {
  if (text === '') {
    return null as T;
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new APIError(status, null, 'The API answered with a body that is not JSON', headers, text);
  }
  if (!parsed || typeof parsed !== 'object' || !('data' in parsed)) {
    throw new APIError(status, null, 'The API answered without a "data" field', headers, text);
  }
  return (parsed as { data: T }).data;
}

function headersToRecord(headers: Headers): Record<string, string> {
  const out: Record<string, string> = {};
  headers.forEach((value, name) => {
    out[name.toLowerCase()] = value;
  });
  return out;
}

function retryWait(status: number, headers: Record<string, string>, attempt: number): number | null {
  if (!RETRY_STATUSES.has(status)) {
    return null;
  }
  const header = headers['retry-after'];
  if (header !== undefined && header.trim() !== '' && Number.isFinite(Number(header))) {
    const wait = Math.max(0, Number(header) * 1000);
    return wait <= MAX_RETRY_WAIT_MS ? wait : null;
  }
  return backoff(attempt);
}

function backoff(attempt: number): number {
  return Math.min(8000, 500 * 2 ** attempt);
}
