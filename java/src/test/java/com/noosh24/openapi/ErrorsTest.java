package com.noosh24.openapi;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.api.Test;

class ErrorsTest {
    private final MockTransport http = new MockTransport();

    static Stream<Arguments> cases() {
        return Stream.of(
                Arguments.of(400, "validation_error", ValidationException.class, ApiException.class),
                Arguments.of(401, "no_api_key", NoApiKeyException.class, AuthenticationException.class),
                Arguments.of(401, "invalid_api_key", InvalidApiKeyException.class, AuthenticationException.class),
                Arguments.of(403, "insufficient_scope", InsufficientScopeException.class, PermissionDeniedException.class),
                Arguments.of(403, "module_not_enabled", ModuleNotEnabledException.class, PermissionDeniedException.class),
                Arguments.of(403, "venue_suspended", VenueSuspendedException.class, PermissionDeniedException.class),
                Arguments.of(403, "not_your_reservation", NotYourReservationException.class, PermissionDeniedException.class),
                Arguments.of(404, "not_found", NotFoundException.class, ApiException.class),
                Arguments.of(404, "table_not_found", TableNotFoundException.class, NotFoundException.class),
                Arguments.of(409, "table_taken", TableTakenException.class, ConflictException.class),
                Arguments.of(409, "cannot_cancel", CannotCancelException.class, ConflictException.class),
                Arguments.of(422, "outside_hours", OutsideHoursException.class, UnprocessableException.class),
                Arguments.of(422, "in_the_past", InThePastException.class, UnprocessableException.class),
                Arguments.of(422, "table_too_small", TableTooSmallException.class, UnprocessableException.class),
                Arguments.of(429, "rate_limit_exceeded", RateLimitException.class, ApiException.class),
                Arguments.of(503, "temporarily_unavailable", TemporarilyUnavailableException.class, ServerException.class),
                Arguments.of(403, "something_new", PermissionDeniedException.class, ApiException.class),
                Arguments.of(409, "something_new", ConflictException.class, ApiException.class),
                Arguments.of(500, "query_failed", ServerException.class, ApiException.class),
                Arguments.of(418, null, ApiException.class, Noosh24Exception.class));
    }

    @ParameterizedTest(name = "{0} {1} -> {2}")
    @MethodSource("cases")
    void mapsErrorCodes(int status, String code, Class<?> type, Class<?> parent) {
        Noosh24Client client = http.builder().maxRetries(0).build();
        http.json(status, code == null ? "{\"nope\": true}" : "{\"error\": \"" + code + "\", \"message\": \"Mesaj\"}");

        ApiException error = assertThrows(ApiException.class, () -> client.customers().get("c1"));

        assertEquals(type, error.getClass());
        assertInstanceOf(parent, error);
        assertInstanceOf(Noosh24Exception.class, error);
        assertInstanceOf(RuntimeException.class, error);
        assertEquals(status, error.getStatus());
        assertEquals(code, error.getCode());
        assertEquals(code == null ? "HTTP " + status : "Mesaj", error.getMessage());
    }

    @Test
    void missingMessageFallsBackToTheCode() {
        http.json(404, "{\"error\": \"not_found\"}");

        NotFoundException error = assertThrows(NotFoundException.class, () -> http.client().orders().get("o1"));
        assertEquals("not_found", error.getMessage());
        assertEquals("application/json", error.getHeaders().get("content-type"));
    }

    @Test
    void errorBodyThatIsNotJsonFallsBackToTheStatus() {
        http.raw(502, "Bad Gateway");

        ServerException error = assertThrows(ServerException.class, () -> http.builder().maxRetries(0).build().whoami());
        assertEquals("HTTP 502", error.getMessage());
        assertEquals("Bad Gateway", error.getBody());
    }

    @Test
    void validationErrorIsNotRetried() {
        http.json(400, "{\"error\": \"validation_error\", \"message\": \"\\\"nope\\\" is not a filterable field on this resource\"}");

        ValidationException error = assertThrows(ValidationException.class,
                () -> http.client().menu().listProducts(ProductListParams.builder().where("nope = 1").build()));
        assertTrue(error.getMessage().contains("not a filterable field"));
        assertEquals(1, http.requests.size());
    }
}
