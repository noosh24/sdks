import 'dart:convert';

import 'package:noosh24/noosh24.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const Map<String, Object?> product = {
  'id': '0b6f3c1e',
  'name': 'Plov',
  'category': 'Main',
  'description': 'Saffron rice with lamb',
  'price': 14,
  'available': true,
  'popular': true,
  'position': 3,
  'prepMinutes': 20,
  'station': '',
  'vatRate': null,
  'vegetarian': false,
  'spicy': false,
  'allergens': ['gluten'],
  'discountable': true,
  'hasModifiers': true,
  'image': 'https://api.noosh24.com/m/5c1d.jpg',
  'video': null,
  'modifierGroups': [
    {
      'id': 'g1',
      'name': 'Size',
      'required': true,
      'position': 0,
      'modifiers': [
        {'id': 'm1', 'name': 'Large', 'priceDelta': 2.5, 'position': 0},
      ],
    },
  ],
  'translations': {
    'en': {'name': 'Pilaf', 'description': 'Rice'},
    'ru': {'name': 'Плов'},
  },
};

const Map<String, Object?> reservation = {
  'id': 'res1',
  'code': 'K7Q2',
  'status': 'pending',
  'source': 'open_api',
  'startsAt': '2026-11-20T15:30:00Z',
  'endsAt': '2026-11-20T17:30:00.123456789Z',
  'guests': 4,
  'zone': 'Terrace',
  'table': {'id': 't5', 'label': 'T5'},
  'guest': {'name': 'Aysel', 'phone': '+994501234567', 'email': null},
  'specialRequest': null,
  'allergyNote': null,
  'birthday': false,
  'childChair': true,
  'depositPaid': 0,
  'preOrder': [
    {'productId': 'p1', 'name': 'Plov', 'price': 14.5, 'qty': 2, 'note': null},
  ],
  'externalRef': 'acme-991',
  'decidedAt': null,
  'createdAt': '2026-11-11T10:00:00.5Z',
  'updatedAt': '2026-11-11T10:00:00Z',
};

NewReservation booking({String? externalRef, String? tableId}) =>
    NewReservation(
      date: CalendarDate(2026, 11, 20),
      time: '19:30',
      guests: 4,
      guestName: 'Aysel Məmmədova',
      phone: '+994501234567',
      tableId: tableId,
      externalRef: externalRef,
    );

void main() {
  test('listProducts sends list parameters and parses the page', () async {
    final h = Harness()..json(200, page([product], 87, limit: 50, offset: 50));

    final result = await h.client.menu.listProducts(
      limit: 50,
      offset: 50,
      sort: ['category asc', 'price desc'],
      where: Where()
          .eq('category', "Chef's")
          .gte('price', 5)
          .eq('available', true),
      expand: ProductExpand.values,
    );

    expect(h.last.url.path, '/v1/menu/products');
    expect(query(h.last), {
      'limit': ['50'],
      'offset': ['50'],
      'sort': ['category asc', 'price desc'],
      'where': ["category = 'Chef''s' AND price >= 5 AND available = true"],
      'expand': ['modifierGroups', 'translations'],
    });
    expect(h.last.url.query, contains('sort=category%20asc'));
    expect(h.last.url.query, isNot(contains('+')));
    expect(result.total, 87);
    expect(result.limit, 50);
    expect(result.offset, 50);
    expect(result.hasMore, isTrue);
    expect(result.nextOffset, 51);
    expect(result.items, hasLength(1));
    final p = result.items.first;
    expect(p.price, 14.0);
    expect(p.price, isA<double>());
    expect(p.vatRate, isNull);
    expect(p.prepMinutes, 20);
    expect(p.allergens, ['gluten']);
    expect(p.modifierGroups.first.modifiers.first.priceDelta, 2.5);
    expect(p.translations['en']?.name, 'Pilaf');
    expect(p.translations['ru']?.description, isNull);
    expect(p.raw, product);
  });

  test('list accepts a plain where and a single sort string', () async {
    final h = Harness()..json(200, page([], 0));

    await h.client.orders.list(
      where: "status = 'served'",
      sort: 'createdAt desc',
    );

    expect(query(h.last), {
      'sort': ['createdAt desc'],
      'where': ["status = 'served'"],
    });
  });

  test('list rejects sort and where of the wrong type', () {
    final h = Harness();
    expect(() => h.client.reviews.list(sort: 2), throwsArgumentError);
    expect(() => h.client.reviews.list(where: 2), throwsArgumentError);
  });

  test('the iterator walks every page', () async {
    final h = Harness()
      ..json(
        200,
        page(
          [
            {'id': 'c1'},
            {'id': 'c2'},
          ],
          5,
          limit: 2,
        ),
      )
      ..json(
        200,
        page(
          [
            {'id': 'c3'},
            {'id': 'c4'},
          ],
          5,
          limit: 2,
          offset: 2,
        ),
      )
      ..json(
        200,
        page(
          [
            {'id': 'c5'},
          ],
          5,
          limit: 2,
          offset: 4,
        ),
      );

    final ids = await h.client.customers
        .iterate(limit: 2, where: "createdAt >= '2026-11-01'")
        .map((c) => c.id)
        .toList();

    expect(ids, ['c1', 'c2', 'c3', 'c4', 'c5']);
    expect(
      [for (final r in h.requests) query(r)['offset']!.single],
      ['0', '2', '4'],
    );
    expect(query(h.requests[2])['where'], ["createdAt >= '2026-11-01'"]);
  });

  test('the iterator starts at the given offset', () async {
    final h = Harness()..json(200, page([], 0, limit: 100, offset: 40));

    await h.client.reviews.iterate(offset: 40).toList();

    expect(query(h.last)['offset'], ['40']);
    expect(query(h.last)['limit'], ['100']);
  });

  test('the iterator is lazy', () async {
    final h = Harness();
    final stream = h.client.payments.iterate();
    await Future<void>.delayed(Duration.zero);
    expect(h.requests, isEmpty);

    h.json(200, page([], 10, limit: 100));
    expect(await stream.toList(), isEmpty);
    expect(h.requests, hasLength(1));
  });

  test('the iterator uses the largest page each endpoint allows', () async {
    final h = Harness();
    for (var i = 0; i < 3; i++) {
      h.json(200, page([], 0));
    }

    await h.client.orders.iterateBills().toList();
    await h.client.menu
        .iterateProducts(expand: [ProductExpand.modifierGroups])
        .toList();
    await h.client.stock.iterateMoves().toList();

    expect(
      [for (final r in h.requests) query(r)['limit']!.single],
      ['50', '50', '100'],
    );
  });

  test('getProduct encodes the id and expand', () async {
    final h = Harness()..json(200, {'data': product});

    final p = await h.client.menu.getProduct(
      'a/b c',
      expand: [ProductExpand.translations],
    );

    expect(
      '${h.last.url}',
      'https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations',
    );
    expect(p.name, 'Plov');
  });

  test('an empty id is rejected', () {
    final h = Harness();
    expect(() => h.client.orders.get(''), throwsArgumentError);
    expect(() => h.client.reservations.cancel(' '), throwsArgumentError);
  });

  test('categories and stop list', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'items': [
            {'name': 'Salads', 'position': 1, 'products': 9, 'available': 8},
          ],
          'total': 1,
        },
      })
      ..json(200, {
        'data': {
          'items': [
            {'id': 'p9', 'name': 'Dolma', 'category': 'Main', 'price': 9.5},
          ],
          'total': 1,
        },
      });

    expect((await h.client.menu.listCategories()).first.available, 8);
    expect((await h.client.menu.getStopList()).first.name, 'Dolma');
    expect(h.requests.map((r) => r.url.path), [
      '/v1/menu/categories',
      '/v1/menu/stop-list',
    ]);
  });

  test('reservation parses nested fields and times', () async {
    final h = Harness()..json(200, {'data': reservation});

    final r = await h.client.reservations.get('res1');

    expect(r.startsAt, DateTime.utc(2026, 11, 20, 15, 30));
    expect(r.startsAt?.isUtc, isTrue);
    expect(r.endsAt, DateTime.utc(2026, 11, 20, 17, 30, 0, 123, 456));
    expect(r.createdAt, DateTime.utc(2026, 11, 11, 10, 0, 0, 500));
    expect(r.decidedAt, isNull);
    expect(r.table?.label, 'T5');
    expect(r.guest?.phone, '+994501234567');
    expect(r.guest?.email, isNull);
    expect(r.preOrder.first.qty, 2);
    expect(r.preOrder.first.price, 14.5);
    expect(r.depositPaid, 0.0);
    expect(r.depositPaid, isA<double>());
  });

  test('timestamps with offsets and plain dates become UTC', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'startsAt': '2026-11-20T19:30:00+04:00',
          'visitedOn': '2026-11-02',
          'createdAt': 'not a time',
        },
      })
      ..json(
        200,
        page([
          {'id': 'rv1', 'visitedOn': '2026-11-02', 'createdAt': 'garbage'},
        ], 1),
      );

    final r = await h.client.reservations.get('res1');
    expect(r.startsAt, DateTime.utc(2026, 11, 20, 15, 30));
    expect(r.createdAt, isNull);
    final review = (await h.client.reviews.list()).items.first;
    expect(review.visitedOn, DateTime.utc(2026, 11, 2));
    expect(review.createdAt, isNull);
  });

  test('availability', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'startsAt': '2026-11-20T15:30:00Z',
          'endsAt': '2026-11-20T17:30:00Z',
          'durationMinutes': 120,
          'openTime': '10:00',
          'closeTime': '23:00',
          'tables': [
            {
              'id': 't5',
              'label': 'T5',
              'hallId': 'h1',
              'zone': 'Terrace',
              'seats': 4,
              'free': true,
            },
          ],
        },
      });

    final result = await h.client.reservations.availability(
      CalendarDate(2026, 11, 20),
      '19:30',
      guests: 4,
    );

    expect(h.last.url.path, '/v1/reservations/availability');
    expect(query(h.last), {
      'date': ['2026-11-20'],
      'time': ['19:30'],
      'guests': ['4'],
    });
    expect(result.durationMinutes, 120);
    expect(result.tables.first.free, isTrue);
  });

  test('availability without guests leaves it out', () async {
    final h = Harness()..json(200, {'data': <String, Object?>{}});

    await h.client.reservations.availability(
      CalendarDate.parse('2026-11-20'),
      '19:30',
    );

    expect(query(h.last).keys, ['date', 'time']);
  });

  test('create posts JSON and reports created', () async {
    final h = Harness()..json(201, {'data': reservation});

    final result = await h.client.reservations.create(
      NewReservation(
        date: CalendarDate(2026, 11, 20),
        time: '19:30',
        guests: 4,
        guestName: 'Aysel Məmmədova',
        phone: '+994501234567',
        childChair: true,
        preOrder: const [
          PreOrderLine(itemId: 'p1', qty: 2),
          PreOrderLine(itemId: 'p2', qty: 1, note: 'no onion'),
        ],
        externalRef: 'acme-991',
      ),
    );

    final request = h.last;
    expect(request.method, 'POST');
    expect('${request.url}', 'https://open-api.noosh24.com/v1/reservations');
    expect(request.headers['content-type'], 'application/json');
    expect(body(request), {
      'date': '2026-11-20',
      'time': '19:30',
      'guests': 4,
      'guestName': 'Aysel Məmmədova',
      'phone': '+994501234567',
      'childChair': true,
      'externalRef': 'acme-991',
      'preOrder': [
        {'itemId': 'p1', 'qty': 2},
        {'itemId': 'p2', 'qty': 1, 'note': 'no onion'},
      ],
    });
    expect(utf8.decode(request.bodyBytes), contains('Məmmədova'));
    expect(result.created, isTrue);
    expect(result.reservation.code, 'K7Q2');
  });

  test(
    'create with a known externalRef returns the existing booking',
    () async {
      final h = Harness()..json(200, {'data': reservation});

      final result = await h.client.reservations.create(
        booking(externalRef: 'acme-991'),
      );

      expect(result.created, isFalse);
      expect(result.reservation.id, 'res1');
    },
  );

  test('create with an externalRef is retried with the same body', () async {
    final h = Harness()
      ..json(503, {'error': 'temporarily_unavailable'}, {'Retry-After': '0'})
      ..json(201, {'data': reservation});

    final result = await h.client.reservations.create(
      booking(externalRef: 'acme-991'),
    );

    expect(result.created, isTrue);
    expect(h.requests, hasLength(2));
    expect(h.requests[0].bodyBytes, h.requests[1].bodyBytes);
    expect(h.sleeps, [Duration.zero]);
  });

  test('create without an externalRef is never retried', () async {
    final h = Harness()
      ..json(503, {'error': 'temporarily_unavailable'}, {'Retry-After': '0'});

    await expectLater(
      h.client.reservations.create(booking()),
      throwsA(isA<ServerException>()),
    );
    expect(h.requests, hasLength(1));
  });

  test('create with a blank externalRef is never retried', () async {
    final h = Harness()..json(502, {'error': 'bad_gateway'});

    await expectLater(
      h.client.reservations.create(booking(externalRef: '  ')),
      throwsA(isA<ServerException>()),
    );
    expect(h.requests, hasLength(1));
  });

  test('table taken', () async {
    final h = Harness()
      ..json(409, {
        'error': 'table_taken',
        'message': 'Bu masa seçilən vaxt üçün artıq tutulub',
      });

    await expectLater(
      h.client.reservations.create(booking(tableId: 't5', externalRef: 'x')),
      throwsA(
        isA<TableTakenException>().having(
          (e) => e.message,
          'message',
          contains('artıq tutulub'),
        ),
      ),
    );
    expect(h.requests, hasLength(1));
  });

  test('cancel', () async {
    final h = Harness()
      ..json(200, {
        'data': {...reservation, 'status': 'cancelled'},
      });

    final r = await h.client.reservations.cancel('res1');

    expect(h.last.method, 'POST');
    expect(
      '${h.last.url}',
      'https://open-api.noosh24.com/v1/reservations/res1/cancel',
    );
    expect(h.last.bodyBytes, isEmpty);
    expect(h.last.headers.containsKey('content-type'), isFalse);
    expect(r.status, 'cancelled');
  });

  test('orders, bills, payments and the Z report', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'id': 'o1',
          'number': 'A-12',
          'dailyNumber': 12,
          'kind': 'delivery',
          'status': 'ready',
          'subtotal': 30,
          'items': [
            {
              'id': 'i1',
              'productId': 'p1',
              'name': 'Plov',
              'qty': 2,
              'price': 15,
              'comp': false,
            },
          ],
          'delivery': {
            'status': 'accepted',
            'platform': {'id': 'wolt', 'name': 'Wolt', 'ref': 'W-1'},
            'fee': 2,
            'acceptedAt': '2026-11-11T09:00:00Z',
          },
        },
      })
      ..json(200, {
        'data': {
          'id': 'b1',
          'status': 'paid',
          'orderIds': ['o1', 'o2'],
          'total': 45.5,
          'closedAt': null,
        },
      })
      ..json(200, {
        'data': {
          'id': 'pay1',
          'method': 'card',
          'amount': 20,
          'card': {
            'maskedPan': '4169********1234',
            'scheme': 'visa',
            'bank': 'Kapital',
          },
          'platform': null,
        },
      })
      ..json(200, {
        'data': {'date': '2026-11-10', 'cash': 120.5},
      })
      ..json(200, {
        'data': {'date': '2026-11-11'},
      });

    final order = await h.client.orders.get('o1');
    final bill = await h.client.orders.getBill('b1');
    final payment = await h.client.payments.get('pay1');
    final z = await h.client.payments.zReport(date: CalendarDate(2026, 11, 10));
    final today = await h.client.payments.zReport();

    expect(order.delivery?.platform?.name, 'Wolt');
    expect(order.delivery?.fee, 2.0);
    expect(order.delivery?.acceptedAt, DateTime.utc(2026, 11, 11, 9));
    expect(order.items.first.price, 15.0);
    expect(bill.orderIds, ['o1', 'o2']);
    expect(bill.closedAt, isNull);
    expect(payment.card?.maskedPan, '4169********1234');
    expect(payment.platform, isNull);
    expect(z['cash'], 120.5);
    expect(query(h.requests[3]), {
      'date': ['2026-11-10'],
    });
    expect(today['date'], '2026-11-11');
    expect(h.last.url.query, isEmpty);
    expect(h.requests.map((r) => r.url.path), [
      '/v1/orders/o1',
      '/v1/bills/b1',
      '/v1/payments/pay1',
      '/v1/reports/z',
      '/v1/reports/z',
    ]);
  });

  test('tables, loyalty, stock and reviews', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'items': [
            {
              'id': 't1',
              'label': 'T1',
              'status': 'occupied',
              'billTotal': 42.1,
            },
          ],
          'total': 1,
        },
      })
      ..json(200, {
        'data': {
          'stampsNeeded': 8,
          'earnBy': 'visit',
          'rewardProductIds': ['p1'],
        },
      })
      ..json(
        200,
        page(
          [
            {'id': 'card1', 'stamps': 5, 'lastVisitAt': null},
          ],
          1,
          limit: 100,
        ),
      )
      ..json(
        200,
        page([
          {
            'id': 'ing1',
            'name': 'Rice',
            'stock': 12,
            'byStore': {'s1': 10, 's2': 2.5},
          },
        ], 1),
      )
      ..json(200, {
        'data': {
          'items': [
            {
              'id': 's1',
              'name': 'Main',
              'isDefault': true,
              'stations': ['hot'],
            },
          ],
          'total': 1,
        },
      })
      ..json(
        200,
        page([
          {
            'id': 'rv1',
            'overall': 4.5,
            'ratings': {'food': 5, 'service': 4},
            'reply': null,
          },
        ], 1),
      )
      ..json(200, {
        'data': {
          'items': [
            {'id': 'h1', 'name': 'Main', 'position': 0},
          ],
          'total': 1,
        },
      });

    expect((await h.client.tables.list()).first.billTotal, 42.1);
    expect((await h.client.loyalty.getProgram()).stampsNeeded, 8);
    expect((await h.client.loyalty.listCards()).hasMore, isFalse);
    expect((await h.client.stock.listIngredients()).items.first.byStore, {
      's1': 10.0,
      's2': 2.5,
    });
    expect((await h.client.stock.listStores()).first.isDefault, isTrue);
    final review = (await h.client.reviews.list()).items.first;
    expect(review.ratings?.food, 5.0);
    expect(review.ratings?.price, isNull);
    expect((await h.client.tables.listHalls()).first.name, 'Main');
    expect(h.requests.map((r) => r.url.path), [
      '/v1/tables',
      '/v1/loyalty/program',
      '/v1/loyalty/cards',
      '/v1/stock/ingredients',
      '/v1/stock/stores',
      '/v1/reviews',
      '/v1/halls',
    ]);
  });

  test('every iterate method reaches its own path', () async {
    final h = Harness();
    for (var i = 0; i < 8; i++) {
      h.json(200, page([], 0));
    }
    final c = h.client;

    await c.reservations.iterate().toList();
    await c.orders.iterate().toList();
    await c.payments.iterate().toList();
    await c.customers.iterate().toList();
    await c.loyalty.iterateCards().toList();
    await c.stock.iterateIngredients().toList();
    await c.reviews.iterate().toList();
    await c.menu.iterateProducts().toList();

    expect(h.requests.map((r) => r.url.path), [
      '/v1/reservations',
      '/v1/orders',
      '/v1/payments',
      '/v1/customers',
      '/v1/loyalty/cards',
      '/v1/stock/ingredients',
      '/v1/reviews',
      '/v1/menu/products',
    ]);
    expect(query(h.last)['limit'], ['100']);
  });

  test('models tolerate missing and unknown fields', () async {
    final h = Harness()
      ..json(201, {
        'data': {
          'id': 'res9',
          'code': 'ZZ11',
          'status': 'pending',
          'brandNew': 1,
          'guests': 'four',
        },
      });

    final result = await h.client.reservations.create(booking());

    expect(result.created, isTrue);
    expect(result.reservation.code, 'ZZ11');
    expect(result.reservation.guest, isNull);
    expect(result.reservation.guests, isNull);
    expect(result.reservation.preOrder, isEmpty);
    expect(result.reservation.raw['brandNew'], 1);
  });

  test('model lists and maps are unmodifiable', () async {
    final h = Harness()..json(200, {'data': product});

    final p = await h.client.menu.getProduct('p1');

    expect(() => p.allergens.add('nuts'), throwsUnsupportedError);
    expect(() => p.raw['name'] = 'x', throwsUnsupportedError);
  });
}
