import type { Noosh24 } from '../client.js';
import type { Bill, Order } from '../models.js';
import { fetchPage, paginate, pathId, type ListParams, type Page } from '../pagination.js';

export class Orders {
  constructor(private readonly client: Noosh24) {}

  list(params: ListParams = {}): Promise<Page<Order>> {
    return fetchPage<Order>(this.client, '/orders', params);
  }

  iterate(params: ListParams = {}): AsyncGenerator<Order, void, undefined> {
    return paginate<Order>(this.client, '/orders', params, 100);
  }

  async get(orderId: string): Promise<Order> {
    return (await this.client.request<Order>('GET', `/orders/${pathId(orderId)}`)).data;
  }

  listBills(params: ListParams = {}): Promise<Page<Bill>> {
    return fetchPage<Bill>(this.client, '/bills', params);
  }

  iterateBills(params: ListParams = {}): AsyncGenerator<Bill, void, undefined> {
    return paginate<Bill>(this.client, '/bills', params, 50);
  }

  async getBill(billId: string): Promise<Bill> {
    return (await this.client.request<Bill>('GET', `/bills/${pathId(billId)}`)).data;
  }
}
