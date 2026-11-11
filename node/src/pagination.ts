import type { Noosh24 } from './client.js';
import { Where } from './where.js';

export interface ListParams {
  limit?: number;
  offset?: number;
  sort?: string | readonly string[];
  where?: string | Where;
}

export interface ProductListParams extends ListParams {
  expand?: ProductExpand | readonly ProductExpand[];
}

export type ProductExpand = 'modifierGroups' | 'translations';

export interface Page<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
  nextOffset: number;
}

interface ListBody<T> {
  items?: T[];
  total?: number;
  limit?: number;
  offset?: number;
}

const listKeys = new Set(['limit', 'offset', 'sort', 'where', 'expand']);

export function listQuery(params: ProductListParams): Record<string, string | number | string[]> {
  const unknown = Object.keys(params).filter((key) => !listKeys.has(key));
  if (unknown.length > 0) {
    throw new TypeError(`Unknown list parameter: ${unknown.join(', ')}`);
  }
  const query: Record<string, string | number | string[]> = {};
  if (params.limit !== undefined) query.limit = params.limit;
  if (params.offset !== undefined) query.offset = params.offset;
  const sort = toList(params.sort);
  if (sort.length > 0) query.sort = sort;
  if (params.where !== undefined) {
    const text = params.where instanceof Where ? params.where.toString() : String(params.where);
    if (text !== '') query.where = text;
  }
  const expand = toList(params.expand);
  if (expand.length > 0) query.expand = expand;
  return query;
}

export function toList<T extends string>(value: T | readonly T[] | undefined): T[] {
  if (value === undefined || value === '') return [];
  return Array.isArray(value) ? [...(value as readonly T[])] : [value as T];
}

export async function fetchPage<T>(client: Noosh24, path: string, params: ProductListParams): Promise<Page<T>> {
  const { data } = await client.request<ListBody<T>>('GET', path, { query: listQuery(params) });
  const items = data?.items ?? [];
  const offset = data?.offset ?? params.offset ?? 0;
  const total = data?.total ?? items.length;
  return {
    items,
    total,
    limit: data?.limit ?? params.limit ?? items.length,
    offset,
    hasMore: items.length > 0 && offset + items.length < total,
    nextOffset: offset + items.length,
  };
}

export async function* paginate<T>(client: Noosh24, path: string, params: ProductListParams, pageSize: number): AsyncGenerator<T, void, undefined> {
  let current: ProductListParams = { ...params, limit: params.limit ?? pageSize, offset: params.offset ?? 0 };
  for (;;) {
    const page = await fetchPage<T>(client, path, current);
    yield* page.items;
    if (!page.hasMore) return;
    current = { ...current, offset: page.nextOffset };
  }
}

export async function fetchAll<T>(client: Noosh24, path: string): Promise<T[]> {
  const { data } = await client.request<ListBody<T>>('GET', path);
  return data?.items ?? [];
}

export function pathId(id: string): string {
  if (typeof id !== 'string' || id.trim() === '') {
    throw new TypeError('An id is required');
  }
  return encodeURIComponent(id);
}
