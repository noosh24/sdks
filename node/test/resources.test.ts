import { describe, expect, it } from 'vitest';
import { ServerError, TableTakenError, where, type Product, type Reservation } from '../src/index.js';
import { page, query, setup } from './helpers.js';

const product: Product = {
  id: '0b6f3c1e', name: 'Plov', category: 'Main', description: 'Saffron rice with lamb', price: 14.5, available: true,
  popular: true, position: 3, prepMinutes: 20, station: '', vatRate: null, vegetarian: false, spicy: false,
  allergens: ['gluten'], discountable: true, hasModifiers: true, image: 'https://api.noosh24.com/m/5c1d.jpg', video: null,
  modifierGroups: [{ id: 'g1', name: 'Size', required: true, position: 0, modifiers: [{ id: 'm1', name: 'Large', priceDelta: 2.5, position: 0 }] }],
  translations: { en: { name: 'Pilaf', description: 'Rice' } },
};

const reservation: Reservation = {
  id: 'res1', code: 'K7Q2', status: 'pending', source: 'open_api', startsAt: '2026-11-20T15:30:00Z', endsAt: '2026-11-20T17:30:00Z',
  guests: 4, zone: 'Terrace', table: { id: 't5', label: 'T5' }, guest: { name: 'Aysel', phone: '+994501234567', email: null },
  specialRequest: null, allergyNote: null, birthday: false, childChair: true, depositPaid: 0,
  preOrder: [{ productId: 'p1', name: 'Plov', price: 14.5, qty: 2, note: null }], externalRef: 'acme-991', decidedAt: null,
  createdAt: '2026-11-11T10:00:00Z', updatedAt: '2026-11-11T10:00:00Z',
};

const booking = { date: '2026-11-20', time: '19:30', guests: 4, guestName: 'Aysel Məmmədova', phone: '+994501234567' };

describe('menu', () => {
  it('sends list parameters and returns a page', async () => {
    const { client, http } = setup();
    http.json(200, page([product], 87, 50, 50));

    const result = await client.menu.listProducts({
      limit: 50,
      offset: 50,
      sort: ['category asc', 'price desc'],
      where: where().eq('category', "Chef's").gte('price', 5).eq('available', true),
      expand: ['modifierGroups', 'translations'],
    });

    expect(new URL(http.last.url).pathname).toBe('/v1/menu/products');
    expect(query(http.last)).toEqual({
      limit: ['50'],
      offset: ['50'],
      sort: ['category asc', 'price desc'],
      where: ["category = 'Chef''s' AND price >= 5 AND available = true"],
      expand: ['modifierGroups', 'translations'],
    });
    expect(result).toMatchObject({ total: 87, limit: 50, offset: 50, hasMore: true, nextOffset: 51 });
    expect(result.items[0].modifierGroups?.[0].modifiers[0].priceDelta).toBe(2.5);
    expect(result.items[0].translations?.en.name).toBe('Pilaf');
  });

  it('rejects an unknown list parameter', async () => {
    const { client } = setup();
    await expect(client.reviews.list({ page: 2 } as never)).rejects.toThrow('page');
  });

  it('gets a product with an encoded id and expand', async () => {
    const { client, http } = setup();
    http.json(200, { data: product });

    const result = await client.menu.getProduct('a/b c', { expand: 'translations' });

    expect(http.last.url).toBe('https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations');
    expect(result.name).toBe('Plov');
  });

  it('rejects an empty id', async () => {
    const { client } = setup();
    await expect(client.orders.get('')).rejects.toThrow(TypeError);
  });

  it('lists categories and the stop list', async () => {
    const { client, http } = setup();
    http
      .json(200, { data: { items: [{ name: 'Salads', position: 1, products: 9, available: 8 }], total: 1 } })
      .json(200, { data: { items: [{ id: 'p9', name: 'Dolma', category: 'Main', price: 9.5 }], total: 1 } });

    expect((await client.menu.listCategories())[0].available).toBe(8);
    expect((await client.menu.getStopList())[0].name).toBe('Dolma');
    expect(http.last.url).toMatch(/\/v1\/menu\/stop-list$/);
  });
});

describe('pagination', () => {
  it('walks every page', async () => {
    const { client, http } = setup();
    http
      .json(200, page([{ id: 'c1' }, { id: 'c2' }], 5, 2, 0))
      .json(200, page([{ id: 'c3' }, { id: 'c4' }], 5, 2, 2))
      .json(200, page([{ id: 'c5' }], 5, 2, 4));

    const ids: string[] = [];
    for await (const customer of client.customers.iterate({ limit: 2, where: "createdAt >= '2026-11-01'" })) {
      ids.push(customer.id);
    }

    expect(ids).toEqual(['c1', 'c2', 'c3', 'c4', 'c5']);
    expect(http.calls.map((call) => query(call).offset[0])).toEqual(['0', '2', '4']);
    expect(query(http.calls[2]).where).toEqual(["createdAt >= '2026-11-01'"]);
  });

  it('stops on an empty page', async () => {
    const { client, http } = setup();
    http.json(200, page([], 10, 100, 0));

    const seen = [];
    for await (const payment of client.payments.iterate()) seen.push(payment);

    expect(seen).toEqual([]);
    expect(http.calls).toHaveLength(1);
  });

  it('uses the largest page each endpoint allows', async () => {
    const { client, http } = setup();
    http.json(200, page([], 0)).json(200, page([], 0)).json(200, page([], 0));

    for await (const _ of client.orders.iterateBills()) void _;
    for await (const _ of client.menu.iterateProducts({ expand: 'modifierGroups' })) void _;
    for await (const _ of client.stock.iterateMoves()) void _;

    expect(http.calls.map((call) => query(call).limit[0])).toEqual(['50', '50', '100']);
  });
});

describe('reservations', () => {
  it('gets one', async () => {
    const { client, http } = setup();
    http.json(200, { data: reservation });

    const result = await client.reservations.get('res1');

    expect(result.table?.label).toBe('T5');
    expect(result.guest.email).toBeNull();
    expect(http.last.url).toBe('https://open-api.noosh24.com/v1/reservations/res1');
  });

  it('checks availability', async () => {
    const { client, http } = setup();
    http.json(200, {
      data: {
        startsAt: '2026-11-20T15:30:00Z', endsAt: '2026-11-20T17:30:00Z', durationMinutes: 120, openTime: '10:00', closeTime: '23:00',
        tables: [{ id: 't5', label: 'T5', hallId: 'h1', zone: 'Terrace', seats: 4, free: true }],
      },
    });

    const result = await client.reservations.availability('2026-11-20', '19:30', 4);

    expect(query(http.last)).toEqual({ date: ['2026-11-20'], time: ['19:30'], guests: ['4'] });
    expect(result.tables[0].free).toBe(true);
  });

  it('creates one and reports created', async () => {
    const { client, http } = setup();
    http.json(201, { data: reservation });

    const result = await client.reservations.create({ ...booking, preOrder: [{ itemId: 'p1', qty: 2 }], externalRef: 'acme-991' });

    expect(http.last.method).toBe('POST');
    expect(http.last.url).toBe('https://open-api.noosh24.com/v1/reservations');
    expect(http.last.headers['Content-Type']).toBe('application/json');
    expect(JSON.parse(http.last.body ?? '')).toEqual({ ...booking, preOrder: [{ itemId: 'p1', qty: 2 }], externalRef: 'acme-991' });
    expect(result.created).toBe(true);
    expect(result.reservation.code).toBe('K7Q2');
  });

  it('returns the existing booking for a known externalRef', async () => {
    const { client, http } = setup();
    http.json(200, { data: reservation });

    const result = await client.reservations.create({ ...booking, externalRef: 'acme-991' });

    expect(result.created).toBe(false);
    expect(result.reservation.id).toBe('res1');
  });

  it('retries a create that carries an externalRef', async () => {
    const { client, http } = setup();
    http.json(503, { error: 'temporarily_unavailable' }, { 'Retry-After': '0' }).json(201, { data: reservation });

    const result = await client.reservations.create({ ...booking, externalRef: 'acme-991' });

    expect(result.created).toBe(true);
    expect(http.calls).toHaveLength(2);
    expect(http.calls[0].body).toBe(http.calls[1].body);
  });

  it('never retries a create without an externalRef', async () => {
    const { client, http } = setup();
    http.json(503, { error: 'temporarily_unavailable' }, { 'Retry-After': '0' });

    await expect(client.reservations.create(booking)).rejects.toBeInstanceOf(ServerError);
    expect(http.calls).toHaveLength(1);
  });

  it('raises table_taken', async () => {
    const { client, http } = setup();
    http.json(409, { error: 'table_taken', message: 'Bu masa seçilən vaxt üçün artıq tutulub' });

    await expect(client.reservations.create({ ...booking, tableId: 't5', externalRef: 'x' })).rejects.toBeInstanceOf(TableTakenError);
  });

  it('cancels', async () => {
    const { client, http } = setup();
    http.json(200, { data: { ...reservation, status: 'cancelled' } });

    const result = await client.reservations.cancel('res1');

    expect(http.last.method).toBe('POST');
    expect(http.last.url).toBe('https://open-api.noosh24.com/v1/reservations/res1/cancel');
    expect(http.last.body).toBeUndefined();
    expect(result.status).toBe('cancelled');
  });
});

describe('other resources', () => {
  it('reads orders, bills, payments and the Z-report', async () => {
    const { client, http } = setup();
    http
      .json(200, { data: { id: 'o1', kind: 'delivery', delivery: { platform: { id: 'wolt', name: 'Wolt', ref: 'W-1' }, fee: 2 } } })
      .json(200, { data: { id: 'b1', orderIds: ['o1', 'o2'], total: 45.5 } })
      .json(200, { data: { id: 'pay1', method: 'card', card: { maskedPan: '4169********1234', scheme: 'visa', bank: 'Kapital' }, platform: null } })
      .json(200, { data: { date: '2026-11-10', cash: 120.5 } });

    expect((await client.orders.get('o1')).delivery?.platform?.name).toBe('Wolt');
    expect((await client.orders.getBill('b1')).orderIds).toEqual(['o1', 'o2']);
    expect((await client.payments.get('pay1')).card?.scheme).toBe('visa');
    expect((await client.payments.zReport('2026-11-10')).cash).toBe(120.5);
    expect(query(http.last)).toEqual({ date: ['2026-11-10'] });
    expect(http.calls.map((call) => new URL(call.url).pathname)).toEqual(['/v1/orders/o1', '/v1/bills/b1', '/v1/payments/pay1', '/v1/reports/z']);
  });

  it('reads tables, loyalty, stock and reviews', async () => {
    const { client, http } = setup();
    http
      .json(200, { data: { items: [{ id: 't1', billTotal: 42.1 }], total: 1 } })
      .json(200, { data: { stampsNeeded: 8 } })
      .json(200, page([{ id: 'card1', stamps: 5 }], 1, 100))
      .json(200, page([{ id: 'ing1', byStore: { s1: 10, s2: 2.5 } }], 1))
      .json(200, { data: { items: [{ id: 's1', isDefault: true }], total: 1 } })
      .json(200, page([{ id: 'rv1', ratings: { food: 5 } }], 1));

    expect((await client.tables.list())[0].billTotal).toBe(42.1);
    expect((await client.loyalty.getProgram()).stampsNeeded).toBe(8);
    expect((await client.loyalty.listCards()).hasMore).toBe(false);
    expect((await client.stock.listIngredients()).items[0].byStore).toEqual({ s1: 10, s2: 2.5 });
    expect((await client.stock.listStores())[0].isDefault).toBe(true);
    expect((await client.reviews.list()).items[0].ratings.food).toBe(5);
    expect(http.calls.map((call) => new URL(call.url).pathname)).toEqual([
      '/v1/tables', '/v1/loyalty/program', '/v1/loyalty/cards', '/v1/stock/ingredients', '/v1/stock/stores', '/v1/reviews',
    ]);
  });
});
