import type { Noosh24 } from '../client.js';
import type { Review } from '../models.js';
import { fetchPage, paginate, type ListParams, type Page } from '../pagination.js';

export class Reviews {
  constructor(private readonly client: Noosh24) {}

  list(params: ListParams = {}): Promise<Page<Review>> {
    return fetchPage<Review>(this.client, '/reviews', params);
  }

  iterate(params: ListParams = {}): AsyncGenerator<Review, void, undefined> {
    return paginate<Review>(this.client, '/reviews', params, 100);
  }
}
