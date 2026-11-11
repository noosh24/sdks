import 'dart:convert';

import 'convert.dart';

sealed class Noosh24Exception implements Exception {
  Noosh24Exception(this.message);

  final String message;

  @override
  String toString() => 'Noosh24Exception: $message';
}

final class ApiConnectionException extends Noosh24Exception {
  ApiConnectionException(super.message, {this.cause});

  final Object? cause;

  @override
  String toString() => 'ApiConnectionException: $message';
}

final class ApiTimeoutException extends ApiConnectionException {
  ApiTimeoutException(super.message, {super.cause});

  @override
  String toString() => 'ApiTimeoutException: $message';
}

final class ApiException extends Noosh24Exception {
  ApiException(
    this.status,
    this.code,
    super.message, {
    Map<String, String> headers = const {},
    this.body = '',
  }) : headers = Map.unmodifiable({
         for (final entry in headers.entries)
           entry.key.toLowerCase(): entry.value,
       });

  final int status;
  final String? code;
  final Map<String, String> headers;
  final String body;

  @override
  String toString() =>
      'ApiException: HTTP $status${code == null ? '' : ' $code'}: $message';
}

final class ValidationException extends ApiException {
  ValidationException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class AuthenticationException extends ApiException {
  AuthenticationException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class NoApiKeyException extends AuthenticationException {
  NoApiKeyException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class InvalidApiKeyException extends AuthenticationException {
  InvalidApiKeyException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class PermissionDeniedException extends ApiException {
  PermissionDeniedException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class InsufficientScopeException extends PermissionDeniedException {
  InsufficientScopeException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class ModuleNotEnabledException extends PermissionDeniedException {
  ModuleNotEnabledException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class VenueSuspendedException extends PermissionDeniedException {
  VenueSuspendedException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class NotYourReservationException extends PermissionDeniedException {
  NotYourReservationException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class NotFoundException extends ApiException {
  NotFoundException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class TableNotFoundException extends NotFoundException {
  TableNotFoundException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class ConflictException extends ApiException {
  ConflictException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class TableTakenException extends ConflictException {
  TableTakenException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class CannotCancelException extends ConflictException {
  CannotCancelException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class UnprocessableException extends ApiException {
  UnprocessableException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class OutsideHoursException extends UnprocessableException {
  OutsideHoursException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class InThePastException extends UnprocessableException {
  InThePastException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class TableTooSmallException extends UnprocessableException {
  TableTooSmallException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class RateLimitException extends ApiException {
  RateLimitException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });

  int? get retryAfter {
    final value = headers['retry-after'];
    if (value == null) {
      return null;
    }
    final seconds = double.tryParse(value.trim());
    if (seconds == null || !seconds.isFinite) {
      return null;
    }
    return seconds < 0 ? 0 : seconds.truncate();
  }
}

final class ServerException extends ApiException {
  ServerException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

final class TemporarilyUnavailableException extends ServerException {
  TemporarilyUnavailableException(
    super.status,
    super.code,
    super.message, {
    super.headers,
    super.body,
  });
}

typedef _Factory =
    ApiException Function(
      int status,
      String? code,
      String message, {
      Map<String, String> headers,
      String body,
    });

const Map<String, _Factory> _byCode = {
  'validation_error': ValidationException.new,
  'no_api_key': NoApiKeyException.new,
  'invalid_api_key': InvalidApiKeyException.new,
  'insufficient_scope': InsufficientScopeException.new,
  'module_not_enabled': ModuleNotEnabledException.new,
  'venue_suspended': VenueSuspendedException.new,
  'not_your_reservation': NotYourReservationException.new,
  'not_found': NotFoundException.new,
  'table_not_found': TableNotFoundException.new,
  'table_taken': TableTakenException.new,
  'cannot_cancel': CannotCancelException.new,
  'outside_hours': OutsideHoursException.new,
  'in_the_past': InThePastException.new,
  'table_too_small': TableTooSmallException.new,
  'rate_limit_exceeded': RateLimitException.new,
  'temporarily_unavailable': TemporarilyUnavailableException.new,
};

const Map<int, _Factory> _byStatus = {
  400: ValidationException.new,
  401: AuthenticationException.new,
  403: PermissionDeniedException.new,
  404: NotFoundException.new,
  409: ConflictException.new,
  422: UnprocessableException.new,
  429: RateLimitException.new,
};

ApiException errorFromResponse(
  int status,
  Map<String, String> headers,
  String body,
) {
  String? code;
  var message = '';
  Object? parsed;
  try {
    parsed = jsonDecode(body);
  } on FormatException {
    parsed = null;
  }
  if (asJsonMap(parsed) case final map?) {
    if (map['error'] case final String error) {
      code = error;
    }
    if (map['message'] case final String text) {
      message = text;
    }
  }
  if (message.isEmpty) {
    message = code ?? 'HTTP $status';
  }
  final factory =
      _byCode[code] ??
      _byStatus[status] ??
      (status >= 500 ? ServerException.new : ApiException.new);
  return factory(status, code, message, headers: headers, body: body);
}
