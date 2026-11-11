part of 'client.dart';

typedef _Factory<T> = T Function(Map<String, dynamic> json);

enum ProductExpand { modifierGroups, translations }

String _id(String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, 'id', 'An id is required');
  }
  return Uri.encodeComponent(value);
}

List<String> _sorts(Object? sort) => switch (sort) {
  null => const [],
  String() => sort.isEmpty ? const [] : [sort],
  Iterable<String>() => sort.toList(),
  _ => throw ArgumentError.value(
    sort,
    'sort',
    'Expected a String or an Iterable<String>',
  ),
};

String? _where(Object? where) => switch (where) {
  null => null,
  String() => where.isEmpty ? null : where,
  Where() => where.isEmpty ? null : '$where',
  _ => throw ArgumentError.value(
    where,
    'where',
    'Expected a String or a Where',
  ),
};

Map<String, Object?> _listQuery(
  int? limit,
  int? offset,
  Object? sort,
  Object? where, [
  Iterable<ProductExpand> expand = const [],
]) {
  final sorts = _sorts(sort);
  final expands = [for (final e in expand) e.name];
  return {
    'limit': limit,
    'offset': offset,
    if (sorts.isNotEmpty) 'sort': sorts,
    'where': _where(where),
    if (expands.isNotEmpty) 'expand': expands,
  };
}

abstract base class _Resource {
  _Resource(this._client);

  final Noosh24Client _client;

  Future<Page<T>> _page<T>(
    String path,
    _Factory<T> factory,
    Map<String, Object?> query,
  ) async {
    final response = await _client.request('GET', path, query: query);
    final data = asJsonMap(response.data) ?? const {};
    final items = readList(data['items'], factory);
    return Page(
      items: items,
      total: readInt(data['total']) ?? items.length,
      limit: readInt(data['limit']) ?? query['limit'] as int? ?? items.length,
      offset: readInt(data['offset']) ?? query['offset'] as int? ?? 0,
    );
  }

  Stream<T> _paginate<T>(
    String path,
    _Factory<T> factory,
    Map<String, Object?> query,
    int pageSize,
  ) async* {
    final current = {
      ...query,
      'limit': query['limit'] ?? pageSize,
      'offset': query['offset'] ?? 0,
    };
    while (true) {
      final page = await _page(path, factory, current);
      for (final item in page.items) {
        yield item;
      }
      if (!page.hasMore) {
        return;
      }
      current['offset'] = page.nextOffset;
    }
  }

  Future<List<T>> _all<T>(String path, _Factory<T> factory) async {
    final response = await _client.request('GET', path);
    return readList(asJsonMap(response.data)?['items'], factory);
  }

  Future<T> _one<T>(
    String path,
    _Factory<T> factory, [
    Map<String, Object?> query = const {},
  ]) async {
    final response = await _client.request('GET', path, query: query);
    return factory(asJsonMap(response.data) ?? const {});
  }
}

final class Menu extends _Resource {
  Menu._(super.client);

  Future<List<Category>> listCategories() =>
      _all('/menu/categories', Category.fromJson);

  Future<Page<Product>> listProducts({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
    Iterable<ProductExpand> expand = const [],
  }) => _page(
    '/menu/products',
    Product.fromJson,
    _listQuery(limit, offset, sort, where, expand),
  );

  Stream<Product> iterateProducts({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
    Iterable<ProductExpand> expand = const [],
  }) => _paginate(
    '/menu/products',
    Product.fromJson,
    _listQuery(limit, offset, sort, where, expand),
    expand.isEmpty ? 100 : 50,
  );

  Future<Product> getProduct(
    String id, {
    Iterable<ProductExpand> expand = const [],
  }) => _one('/menu/products/${_id(id)}', Product.fromJson, {
    'expand': [for (final e in expand) e.name],
  });

  Future<List<StopListItem>> getStopList() =>
      _all('/menu/stop-list', StopListItem.fromJson);
}

final class Reservations extends _Resource {
  Reservations._(super.client);

  Future<Page<Reservation>> list({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/reservations',
    Reservation.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<Reservation> iterate({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/reservations',
    Reservation.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<Reservation> get(String id) =>
      _one('/reservations/${_id(id)}', Reservation.fromJson);

  Future<TableAvailability> availability(
    CalendarDate date,
    String time, {
    int? guests,
  }) => _one('/reservations/availability', TableAvailability.fromJson, {
    'date': '$date',
    'time': time,
    'guests': guests,
  });

  Future<CreateReservationResult> create(NewReservation reservation) async {
    final response = await _client.request(
      'POST',
      '/reservations',
      body: reservation.toJson(),
      retryable: reservation.isIdempotent,
    );
    return CreateReservationResult(
      reservation: Reservation.fromJson(asJsonMap(response.data) ?? const {}),
      created: response.status == 201,
    );
  }

  Future<Reservation> cancel(String id) {
    final path = '/reservations/${_id(id)}/cancel';
    return _client
        .request('POST', path)
        .then((r) => Reservation.fromJson(asJsonMap(r.data) ?? const {}));
  }
}

final class Orders extends _Resource {
  Orders._(super.client);

  Future<Page<Order>> list({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) =>
      _page('/orders', Order.fromJson, _listQuery(limit, offset, sort, where));

  Stream<Order> iterate({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/orders',
    Order.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<Order> get(String id) => _one('/orders/${_id(id)}', Order.fromJson);

  Future<Page<Bill>> listBills({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page('/bills', Bill.fromJson, _listQuery(limit, offset, sort, where));

  Stream<Bill> iterateBills({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/bills',
    Bill.fromJson,
    _listQuery(limit, offset, sort, where),
    50,
  );

  Future<Bill> getBill(String id) => _one('/bills/${_id(id)}', Bill.fromJson);
}

final class Payments extends _Resource {
  Payments._(super.client);

  Future<Page<Payment>> list({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/payments',
    Payment.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<Payment> iterate({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/payments',
    Payment.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<Payment> get(String id) =>
      _one('/payments/${_id(id)}', Payment.fromJson);

  Future<ZReport> zReport({CalendarDate? date}) async {
    final response = await _client.request(
      'GET',
      '/reports/z',
      query: {'date': date?.toString()},
    );
    return Map.unmodifiable(asJsonMap(response.data) ?? const {});
  }
}

final class Tables extends _Resource {
  Tables._(super.client);

  Future<List<Table>> list() => _all('/tables', Table.fromJson);

  Future<List<Hall>> listHalls() => _all('/halls', Hall.fromJson);
}

final class Customers extends _Resource {
  Customers._(super.client);

  Future<Page<Customer>> list({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/customers',
    Customer.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<Customer> iterate({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/customers',
    Customer.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<Customer> get(String id) =>
      _one('/customers/${_id(id)}', Customer.fromJson);
}

final class Loyalty extends _Resource {
  Loyalty._(super.client);

  Future<LoyaltyProgram> getProgram() =>
      _one('/loyalty/program', LoyaltyProgram.fromJson);

  Future<Page<LoyaltyCard>> listCards({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/loyalty/cards',
    LoyaltyCard.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<LoyaltyCard> iterateCards({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/loyalty/cards',
    LoyaltyCard.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );
}

final class Stock extends _Resource {
  Stock._(super.client);

  Future<Page<Ingredient>> listIngredients({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/stock/ingredients',
    Ingredient.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<Ingredient> iterateIngredients({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/stock/ingredients',
    Ingredient.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<Page<StockMove>> listMoves({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/stock/moves',
    StockMove.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<StockMove> iterateMoves({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/stock/moves',
    StockMove.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );

  Future<List<StockStore>> listStores() =>
      _all('/stock/stores', StockStore.fromJson);
}

final class Reviews extends _Resource {
  Reviews._(super.client);

  Future<Page<Review>> list({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _page(
    '/reviews',
    Review.fromJson,
    _listQuery(limit, offset, sort, where),
  );

  Stream<Review> iterate({
    int? limit,
    int? offset,
    Object? sort,
    Object? where,
  }) => _paginate(
    '/reviews',
    Review.fromJson,
    _listQuery(limit, offset, sort, where),
    100,
  );
}
