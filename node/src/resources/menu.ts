import type { Noosh24 } from '../client.js';
import type { Category, Product, StopListItem } from '../models.js';
import { fetchAll, fetchPage, paginate, pathId, toList, type Page, type ProductExpand, type ProductListParams } from '../pagination.js';

export class Menu {
  constructor(private readonly client: Noosh24) {}

  listCategories(): Promise<Category[]> {
    return fetchAll<Category>(this.client, '/menu/categories');
  }

  listProducts(params: ProductListParams = {}): Promise<Page<Product>> {
    return fetchPage<Product>(this.client, '/menu/products', params);
  }

  iterateProducts(params: ProductListParams = {}): AsyncGenerator<Product, void, undefined> {
    return paginate<Product>(this.client, '/menu/products', params, toList(params.expand).length > 0 ? 50 : 100);
  }

  async getProduct(productId: string, options: { expand?: ProductExpand | readonly ProductExpand[] } = {}): Promise<Product> {
    const expand = toList(options.expand);
    const { data } = await this.client.request<Product>('GET', `/menu/products/${pathId(productId)}`, {
      query: expand.length > 0 ? { expand } : {},
    });
    return data;
  }

  getStopList(): Promise<StopListItem[]> {
    return fetchAll<StopListItem>(this.client, '/menu/stop-list');
  }
}
