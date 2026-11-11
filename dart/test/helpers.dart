import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noosh24/noosh24.dart';

final class Harness {
  Harness({
    String? baseUrl,
    String? userAgent,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 30),
  }) {
    client = Noosh24Client(
      'nsk_test_123',
      baseUrl: baseUrl,
      userAgent: userAgent,
      maxRetries: maxRetries,
      timeout: timeout,
      httpClient: MockClient(_handle),
      sleep: (duration) async => sleeps.add(duration),
    );
  }

  late final Noosh24Client client;
  final List<Duration> sleeps = [];
  final List<http.Request> requests = [];
  final List<Object> _queue = [];

  http.Request get last => requests.last;

  void json(
    int status,
    Object? body, [
    Map<String, String> headers = const {},
  ]) {
    _queue.add(
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {
          'content-type': 'application/json',
          for (final entry in headers.entries)
            entry.key.toLowerCase(): entry.value,
        },
      ),
    );
  }

  void raw(int status, String text) {
    _queue.add(http.Response.bytes(utf8.encode(text), status));
  }

  void fail(Exception error) => _queue.add(error);

  void hang() => _queue.add(Completer<http.Response>());

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    if (_queue.isEmpty) {
      throw StateError(
        'No response queued for ${request.method} ${request.url}',
      );
    }
    final next = _queue.removeAt(0);
    return switch (next) {
      http.Response() => next,
      Completer<http.Response>() => next.future,
      Exception() => throw next,
      _ => throw StateError('Bad queue entry $next'),
    };
  }
}

Map<String, List<String>> query(http.Request request) =>
    request.url.queryParametersAll;

Object? body(http.Request request) =>
    jsonDecode(utf8.decode(request.bodyBytes));

Map<String, Object?> page(
  List<Map<String, Object?>> items,
  int total, {
  int limit = 20,
  int offset = 0,
}) => {
  'data': {'items': items, 'total': total, 'limit': limit, 'offset': offset},
};
