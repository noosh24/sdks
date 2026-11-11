import type { Noosh24 } from '../client.js';
import type { LoyaltyCard, LoyaltyProgram } from '../models.js';
import { fetchPage, paginate, type ListParams, type Page } from '../pagination.js';

export class Loyalty {
  constructor(private readonly client: Noosh24) {}

  async getProgram(): Promise<LoyaltyProgram> {
    return (await this.client.request<LoyaltyProgram>('GET', '/loyalty/program')).data;
  }

  listCards(params: ListParams = {}): Promise<Page<LoyaltyCard>> {
    return fetchPage<LoyaltyCard>(this.client, '/loyalty/cards', params);
  }

  iterateCards(params: ListParams = {}): AsyncGenerator<LoyaltyCard, void, undefined> {
    return paginate<LoyaltyCard>(this.client, '/loyalty/cards', params, 100);
  }
}
