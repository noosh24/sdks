import type { Noosh24 } from '../client.js';
import type { Ingredient, StockMove, StockStore } from '../models.js';
import { fetchAll, fetchPage, paginate, type ListParams, type Page } from '../pagination.js';

export class Stock {
  constructor(private readonly client: Noosh24) {}

  listIngredients(params: ListParams = {}): Promise<Page<Ingredient>> {
    return fetchPage<Ingredient>(this.client, '/stock/ingredients', params);
  }

  iterateIngredients(params: ListParams = {}): AsyncGenerator<Ingredient, void, undefined> {
    return paginate<Ingredient>(this.client, '/stock/ingredients', params, 100);
  }

  listMoves(params: ListParams = {}): Promise<Page<StockMove>> {
    return fetchPage<StockMove>(this.client, '/stock/moves', params);
  }

  iterateMoves(params: ListParams = {}): AsyncGenerator<StockMove, void, undefined> {
    return paginate<StockMove>(this.client, '/stock/moves', params, 100);
  }

  listStores(): Promise<StockStore[]> {
    return fetchAll<StockStore>(this.client, '/stock/stores');
  }
}
