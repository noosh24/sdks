import type { Noosh24 } from '../client.js';
import type { Customer } from '../models.js';
import { fetchPage, paginate, pathId, type ListParams, type Page } from '../pagination.js';

export class Customers {
  constructor(private readonly client: Noosh24) {}

  list(params: ListParams = {}): Promise<Page<Customer>> {
    return fetchPage<Customer>(this.client, '/customers', params);
  }

  iterate(params: ListParams = {}): AsyncGenerator<Customer, void, undefined> {
    return paginate<Customer>(this.client, '/customers', params, 100);
  }

  async get(customerId: string): Promise<Customer> {
    return (await this.client.request<Customer>('GET', `/customers/${pathId(customerId)}`)).data;
  }
}
