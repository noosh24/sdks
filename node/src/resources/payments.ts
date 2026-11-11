import type { Noosh24 } from '../client.js';
import type { Payment, ZReport } from '../models.js';
import { fetchPage, paginate, pathId, type ListParams, type Page } from '../pagination.js';

export class Payments {
  constructor(private readonly client: Noosh24) {}

  list(params: ListParams = {}): Promise<Page<Payment>> {
    return fetchPage<Payment>(this.client, '/payments', params);
  }

  iterate(params: ListParams = {}): AsyncGenerator<Payment, void, undefined> {
    return paginate<Payment>(this.client, '/payments', params, 100);
  }

  async get(paymentId: string): Promise<Payment> {
    return (await this.client.request<Payment>('GET', `/payments/${pathId(paymentId)}`)).data;
  }

  async zReport(date?: string): Promise<ZReport> {
    const { data } = await this.client.request<ZReport>('GET', '/reports/z', { query: { date } });
    return data ?? {};
  }
}
