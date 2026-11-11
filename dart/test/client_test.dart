import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:noosh24/noosh24.dart';
import 'package:noosh24/src/client.dart' show buildQuery;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('sends the key and headers to the default base URL', () async {
    final h = Harness()
      ..json(200, {
        'data': {
          'restaurant': {'id': 'r1', 'name': 'Masago', 'slug': 'masago'},
          'key': {
            'id': 'k1',
            'name': 'Wolt',
            'prefix': 'nsk_Ab3dE9xQ',
            'scopes': ['menu:read', 'orders:read'],
          },
          'subscription': {
            'status': 'active',
            'modules': ['loyalty'],
          },
          'features': {'loyalty': true, 'inventory': false},
        },
      });

    final me = await h.client.whoami();

    final request = h.last;
    expect(request.method, 'GET');
    expect('${request.url}', 'https://open-api.noosh24.com/v1/whoami');
    expect(request.headers['authorization'], 'Bearer nsk_test_123');
    expect(request.headers['accept'], 'application/json');
    expect(request.headers['user-agent'], 'noosh24-dart/$packageVersion');
    expect(request.headers.containsKey('content-type'), isFalse);
    expect(request.bodyBytes, isEmpty);
    expect(me.restaurant?.name, 'Masago');
    expect(me.key?.scopes, ['menu:read', 'orders:read']);
    expect(me.subscription?.status, 'active');
    expect(me.features?.loyalty, isTrue);
    expect(me.features?.inventory, isFalse);
  });

  test('custom base URL and user agent', () async {
    final h = Harness(
      baseUrl: 'http://localhost:8080/v1/',
      userAgent: 'acme-pos/2.1',
    )..json(200, {'data': <String, Object?>{}});

    await h.client.whoami();

    expect('${h.last.url}', 'http://localhost:8080/v1/whoami');
    expect(
      h.last.headers['user-agent'],
      'acme-pos/2.1 noosh24-dart/$packageVersion',
    );
  });

  test('rejects an empty key', () {
    expect(() => Noosh24Client(''), throwsArgumentError);
    expect(() => Noosh24Client('  '), throwsArgumentError);
  });

  test('close leaves an injected client open', () async {
    final h = Harness()..json(200, {'data': <String, Object?>{}});
    h.client.close();
    await h.client.whoami();
    expect(h.requests, hasLength(1));
  });

  test('retries a rate limit after Retry-After', () async {
    final h = Harness()
      ..json(
        429,
        {'error': 'rate_limit_exceeded', 'message': 'slow down'},
        {'Retry-After': '3'},
      )
      ..json(200, {
        'data': {'items': <Object?>[], 'total': 0},
      });

    expect(await h.client.tables.list(), isEmpty);
    expect(h.requests, hasLength(2));
    expect(h.sleeps, [const Duration(seconds: 3)]);
  });

  test('gives up after maxRetries and exposes retryAfter', () async {
    final h = Harness(maxRetries: 1)
      ..json(
        429,
        {'error': 'rate_limit_exceeded', 'message': 'slow down'},
        {'Retry-After': '1'},
      )
      ..json(
        429,
        {'error': 'rate_limit_exceeded', 'message': 'slow down'},
        {'Retry-After': '7'},
      );

    final error = await h.client.tables.list().then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );

    expect(error, isA<RateLimitException>());
    final limit = error! as RateLimitException;
    expect(limit.status, 429);
    expect(limit.code, 'rate_limit_exceeded');
    expect(limit.retryAfter, 7);
    expect(limit.message, 'slow down');
    expect(limit.headers['retry-after'], '7');
    expect(h.requests, hasLength(2));
  });

  test('does not wait longer than a minute', () async {
    final h = Harness()
      ..json(429, {'error': 'rate_limit_exceeded'}, {'Retry-After': '120'});

    await expectLater(
      h.client.tables.list(),
      throwsA(
        isA<RateLimitException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          120,
        ),
      ),
    );
    expect(h.requests, hasLength(1));
    expect(h.sleeps, isEmpty);
  });

  test('backs off on temporarily unavailable', () async {
    final h = Harness();
    for (var i = 0; i < 3; i++) {
      h.json(503, {'error': 'temporarily_unavailable', 'message': 'try again'});
    }

    await expectLater(
      h.client.tables.listHalls(),
      throwsA(isA<TemporarilyUnavailableException>()),
    );
    expect(h.requests, hasLength(3));
    expect(h.sleeps, [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
    ]);
  });

  test('retries 502 and 504 without Retry-After', () async {
    final h = Harness()
      ..json(502, {'error': 'bad_gateway'})
      ..json(504, {'error': 'gateway_timeout'})
      ..json(200, {
        'data': {'items': <Object?>[], 'total': 0},
      });

    expect(await h.client.tables.list(), isEmpty);
    expect(h.sleeps, [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
    ]);
  });

  test('retries connection errors on reads', () async {
    final h = Harness(maxRetries: 1)
      ..fail(http.ClientException('connection reset'))
      ..json(200, {
        'data': {
          'items': [
            {'id': 'h1', 'name': 'Main', 'position': 1},
          ],
          'total': 1,
        },
      });

    expect((await h.client.tables.listHalls()).first.name, 'Main');
    expect(h.sleeps, [const Duration(milliseconds: 500)]);

    h
      ..fail(http.ClientException('connection reset'))
      ..fail(http.ClientException('connection reset'));
    await expectLater(
      h.client.tables.listHalls(),
      throwsA(
        isA<ApiConnectionException>()
            .having((e) => e.message, 'message', contains('connection reset'))
            .having((e) => e.cause, 'cause', isA<http.ClientException>()),
      ),
    );
  });

  test('a timeout from the transport is an ApiTimeoutException', () async {
    final h = Harness(maxRetries: 0)..fail(TimeoutException('read timed out'));

    await expectLater(h.client.whoami(), throwsA(isA<ApiTimeoutException>()));
  });

  test('a request slower than timeout is an ApiTimeoutException', () async {
    final h = Harness(maxRetries: 1, timeout: const Duration(milliseconds: 20))
      ..hang()
      ..hang();

    final error = await h.client.whoami().then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );

    expect(error, isA<ApiTimeoutException>());
    expect(error, isA<ApiConnectionException>());
    expect(h.requests, hasLength(2));
    expect(h.sleeps, [const Duration(milliseconds: 500)]);
  });

  test('a body that is not JSON is an ApiException', () async {
    final h = Harness()..raw(200, '<html>gateway</html>');

    await expectLater(
      h.client.whoami(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 200)
            .having((e) => e.body, 'body', '<html>gateway</html>'),
      ),
    );
  });

  test('a 2xx body without data is an ApiException', () async {
    final h = Harness()..json(200, {'items': <Object?>[]});

    await expectLater(h.client.whoami(), throwsA(isA<ApiException>()));
  });

  test('builds repeated query parameters', () {
    expect(
      buildQuery({
        'sort': ['price desc', 'name asc'],
        'where': 'a = 1',
        'skip': null,
        'available': true,
      }),
      'sort=price%20desc&sort=name%20asc&where=a%20%3D%201&available=true',
    );
  });
}
