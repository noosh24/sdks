import 'package:noosh24/noosh24.dart';
import 'package:test/test.dart';

import 'helpers.dart';

typedef Case = (int, String?, Type, TypeMatcher<ApiException>);

final List<Case> cases = [
  (400, 'validation_error', ValidationException, isA<ApiException>()),
  (401, 'no_api_key', NoApiKeyException, isA<AuthenticationException>()),
  (
    401,
    'invalid_api_key',
    InvalidApiKeyException,
    isA<AuthenticationException>(),
  ),
  (
    403,
    'insufficient_scope',
    InsufficientScopeException,
    isA<PermissionDeniedException>(),
  ),
  (
    403,
    'module_not_enabled',
    ModuleNotEnabledException,
    isA<PermissionDeniedException>(),
  ),
  (
    403,
    'venue_suspended',
    VenueSuspendedException,
    isA<PermissionDeniedException>(),
  ),
  (
    403,
    'not_your_reservation',
    NotYourReservationException,
    isA<PermissionDeniedException>(),
  ),
  (404, 'not_found', NotFoundException, isA<ApiException>()),
  (404, 'table_not_found', TableNotFoundException, isA<NotFoundException>()),
  (409, 'table_taken', TableTakenException, isA<ConflictException>()),
  (409, 'cannot_cancel', CannotCancelException, isA<ConflictException>()),
  (422, 'outside_hours', OutsideHoursException, isA<UnprocessableException>()),
  (422, 'in_the_past', InThePastException, isA<UnprocessableException>()),
  (
    422,
    'table_too_small',
    TableTooSmallException,
    isA<UnprocessableException>(),
  ),
  (429, 'rate_limit_exceeded', RateLimitException, isA<ApiException>()),
  (
    503,
    'temporarily_unavailable',
    TemporarilyUnavailableException,
    isA<ServerException>(),
  ),
  (403, 'something_new', PermissionDeniedException, isA<ApiException>()),
  (409, 'something_new', ConflictException, isA<ApiException>()),
  (500, 'query_failed', ServerException, isA<ApiException>()),
  (418, null, ApiException, isA<ApiException>()),
];

void main() {
  for (final (status, code, type, parent) in cases) {
    test('maps $status ${code ?? '(no code)'} to $type', () async {
      final h = Harness(maxRetries: 0)
        ..json(
          status,
          code == null ? {'nope': true} : {'error': code, 'message': 'Mesaj'},
        );

      final error = await h.client.customers
          .get('c1')
          .then<Object?>((_) => null, onError: (Object e) => e);

      expect(error.runtimeType, type);
      expect(error, parent);
      expect(error, isA<Noosh24Exception>());
      final api = error! as ApiException;
      expect(api.status, status);
      expect(api.code, code);
      expect(api.message, code == null ? 'HTTP $status' : 'Mesaj');
    });
  }

  test('a missing message falls back to the code', () async {
    final h = Harness()..json(404, {'error': 'not_found'});

    await expectLater(
      h.client.orders.get('o1'),
      throwsA(
        isA<NotFoundException>().having(
          (e) => e.message,
          'message',
          'not_found',
        ),
      ),
    );
  });

  test('a validation error is not retried', () async {
    final h = Harness()
      ..json(400, {
        'error': 'validation_error',
        'message': '"nope" is not a filterable field on this resource',
      });

    await expectLater(
      h.client.menu.listProducts(where: 'nope = 1'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('not a filterable field'),
        ),
      ),
    );
    expect(h.requests, hasLength(1));
  });

  test('exceptions switch exhaustively over the sealed root', () {
    String kind(Noosh24Exception error) => switch (error) {
      ApiTimeoutException() => 'timeout',
      ApiConnectionException() => 'connection',
      ApiException() => 'api',
    };

    expect(kind(ApiTimeoutException('t')), 'timeout');
    expect(kind(ApiConnectionException('c')), 'connection');
    expect(kind(TableTakenException(409, 'table_taken', 'taken')), 'api');
  });
}
