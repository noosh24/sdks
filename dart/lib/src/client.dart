import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'convert.dart';
import 'dates.dart';
import 'errors.dart';
import 'models.dart';
import 'page.dart';
import 'version.dart';
import 'where.dart';

part 'reservation_input.dart';
part 'resources.dart';

typedef Sleep = Future<void> Function(Duration duration);

typedef ApiResponse = ({int status, Object? data});

const _retryStatuses = {429, 502, 503, 504};
const _maxRetryWait = Duration(seconds: 60);

final class Noosh24Client {
  Noosh24Client(
    String apiKey, {
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
    int maxRetries = 2,
    String? userAgent,
    http.Client? httpClient,
    Sleep? sleep,
  }) : _apiKey = apiKey.trim(),
       baseUrl = (baseUrl ?? defaultBaseUrl).replaceFirst(RegExp(r'/+$'), ''),
       maxRetries = maxRetries < 0 ? 0 : maxRetries,
       userAgent = userAgent == null || userAgent.trim().isEmpty
           ? 'noosh24-dart/$packageVersion'
           : '$userAgent noosh24-dart/$packageVersion',
       _ownsHttp = httpClient == null,
       _http = httpClient ?? http.Client(),
       _sleep = sleep ?? _defaultSleep {
    if (_apiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'An API key is required');
    }
  }

  static const defaultBaseUrl = 'https://open-api.noosh24.com/v1';

  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final String userAgent;

  final String _apiKey;
  final bool _ownsHttp;
  final http.Client _http;
  final Sleep _sleep;

  late final Menu menu = Menu._(this);
  late final Reservations reservations = Reservations._(this);
  late final Orders orders = Orders._(this);
  late final Payments payments = Payments._(this);
  late final Tables tables = Tables._(this);
  late final Customers customers = Customers._(this);
  late final Loyalty loyalty = Loyalty._(this);
  late final Stock stock = Stock._(this);
  late final Reviews reviews = Reviews._(this);

  Future<Whoami> whoami() async {
    final response = await request('GET', '/whoami');
    return Whoami.fromJson(asJsonMap(response.data) ?? const {});
  }

  void close() {
    if (_ownsHttp) {
      _http.close();
    }
  }

  Future<ApiResponse> request(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool retryable = true,
  }) async {
    final queryString = buildQuery(query);
    final url = Uri.parse(
      '$baseUrl$path${queryString.isEmpty ? '' : '?$queryString'}',
    );
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Accept': 'application/json',
      'User-Agent': userAgent,
    };
    List<int>? content;
    if (body != null) {
      headers['Content-Type'] = 'application/json';
      content = utf8.encode(jsonEncode(body));
    }

    for (var attempt = 0; ; attempt++) {
      final http.Response response;
      try {
        response = await _send(method, url, headers, content);
      } on ApiConnectionException {
        if (retryable && attempt < maxRetries) {
          await _sleep(_backoff(attempt));
          continue;
        }
        rethrow;
      }
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (
          status: response.statusCode,
          data: _decode(response.statusCode, response.headers, text),
        );
      }
      final wait = _retryWait(response.statusCode, response.headers, attempt);
      if (retryable && attempt < maxRetries && wait != null) {
        await _sleep(wait);
        continue;
      }
      throw errorFromResponse(response.statusCode, response.headers, text);
    }
  }

  Future<http.Response> _send(
    String method,
    Uri url,
    Map<String, String> headers,
    List<int>? content,
  ) async {
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      method,
      url,
      abortTrigger: abort.future,
    )..headers.addAll(headers);
    if (content != null) {
      request.bodyBytes = content;
    }
    try {
      return await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException catch (error) {
      if (!abort.isCompleted) {
        abort.complete();
      }
      throw ApiTimeoutException(
        'Request timed out after ${_seconds(timeout)} s',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiConnectionException(
        'Could not reach the Noosh24 API: ${error.message}',
        cause: error,
      );
    } on Noosh24Exception {
      rethrow;
    } on Exception catch (error) {
      throw ApiConnectionException(
        'Could not reach the Noosh24 API: $error',
        cause: error,
      );
    }
  }
}

Future<void> _defaultSleep(Duration duration) => Future.delayed(duration);

String buildQuery(Map<String, Object?> query) {
  final parts = <String>[];
  for (final MapEntry(:key, :value) in query.entries) {
    final values = value is Iterable<Object?> ? value : [value];
    for (final item in values) {
      if (item == null) {
        continue;
      }
      parts.add('${_encode(key)}=${_encode('$item')}');
    }
  }
  return parts.join('&');
}

String _encode(String value) =>
    Uri.encodeQueryComponent(value).replaceAll('+', '%20');

Object? _decode(int status, Map<String, String> headers, String text) {
  if (text.isEmpty) {
    return null;
  }
  final Object? parsed;
  try {
    parsed = jsonDecode(text);
  } on FormatException {
    throw ApiException(
      status,
      null,
      'The API answered with a body that is not JSON',
      headers: headers,
      body: text,
    );
  }
  final map = asJsonMap(parsed);
  if (map == null || !map.containsKey('data')) {
    throw ApiException(
      status,
      null,
      'The API answered without a "data" field',
      headers: headers,
      body: text,
    );
  }
  return map['data'];
}

Duration? _retryWait(int status, Map<String, String> headers, int attempt) {
  if (!_retryStatuses.contains(status)) {
    return null;
  }
  final header = headers['retry-after'];
  final seconds = header == null ? null : double.tryParse(header.trim());
  if (seconds == null || !seconds.isFinite) {
    return _backoff(attempt);
  }
  final wait = Duration(
    microseconds: (seconds < 0 ? 0 : seconds * 1000000).round(),
  );
  return wait <= _maxRetryWait ? wait : null;
}

Duration _backoff(int attempt) {
  final ms = 500 * (1 << (attempt > 4 ? 4 : attempt));
  return Duration(milliseconds: ms > 8000 ? 8000 : ms);
}

String _seconds(Duration duration) {
  final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
  return seconds == seconds.truncateToDouble()
      ? '${seconds.toInt()}'
      : '$seconds';
}
