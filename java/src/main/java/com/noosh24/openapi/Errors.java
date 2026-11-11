package com.noosh24.openapi;

import java.util.Map;
import org.jspecify.annotations.Nullable;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;

final class Errors {
    @FunctionalInterface
    interface Factory {
        ApiException create(int status, @Nullable String code, String message, Map<String, String> headers, String body);
    }

    private static final Map<String, Factory> BY_CODE = Map.ofEntries(
            Map.entry("validation_error", ValidationException::new),
            Map.entry("no_api_key", NoApiKeyException::new),
            Map.entry("invalid_api_key", InvalidApiKeyException::new),
            Map.entry("insufficient_scope", InsufficientScopeException::new),
            Map.entry("module_not_enabled", ModuleNotEnabledException::new),
            Map.entry("venue_suspended", VenueSuspendedException::new),
            Map.entry("not_your_reservation", NotYourReservationException::new),
            Map.entry("not_found", NotFoundException::new),
            Map.entry("table_not_found", TableNotFoundException::new),
            Map.entry("table_taken", TableTakenException::new),
            Map.entry("cannot_cancel", CannotCancelException::new),
            Map.entry("outside_hours", OutsideHoursException::new),
            Map.entry("in_the_past", InThePastException::new),
            Map.entry("table_too_small", TableTooSmallException::new),
            Map.entry("rate_limit_exceeded", RateLimitException::new),
            Map.entry("temporarily_unavailable", TemporarilyUnavailableException::new));

    private static final Map<Integer, Factory> BY_STATUS = Map.of(
            400, ValidationException::new,
            401, AuthenticationException::new,
            403, PermissionDeniedException::new,
            404, NotFoundException::new,
            409, ConflictException::new,
            422, UnprocessableException::new,
            429, RateLimitException::new);

    private Errors() {}

    static ApiException fromResponse(int status, Map<String, String> headers, String body) {
        String code = null;
        String message = "";
        try {
            JsonNode parsed = JsonSupport.MAPPER.readTree(body);
            if (parsed != null && parsed.isObject()) {
                JsonNode error = parsed.get("error");
                if (error != null && error.isString()) {
                    code = error.stringValue();
                }
                JsonNode text = parsed.get("message");
                if (text != null && text.isString()) {
                    message = text.stringValue();
                }
            }
        } catch (JacksonException ignored) {
        }
        if (message.isEmpty()) {
            message = code != null && !code.isEmpty() ? code : "HTTP " + status;
        }
        Factory factory = code == null ? null : BY_CODE.get(code);
        if (factory == null) {
            factory = BY_STATUS.get(status);
        }
        if (factory == null) {
            factory = status >= 500 ? ServerException::new : ApiException::new;
        }
        return factory.create(status, code, message, headers, body);
    }
}
