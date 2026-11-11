import type { Noosh24 } from '../client.js';
import type { Hall, Table } from '../models.js';
import { fetchAll } from '../pagination.js';

export class Tables {
  constructor(private readonly client: Noosh24) {}

  list(): Promise<Table[]> {
    return fetchAll<Table>(this.client, '/tables');
  }

  listHalls(): Promise<Hall[]> {
    return fetchAll<Hall>(this.client, '/halls');
  }
}
