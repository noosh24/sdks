package com.noosh24.openapi;

import java.util.Map;
import java.util.OptionalInt;
import org.jspecify.annotations.Nullable;

public class RateLimitException extends ApiException {
    public RateLimitException(int status, @Nullable String code, String message, Map<String, String> headers, String body) {
        super(status, code, message, headers, body);
    }

    public OptionalInt getRetryAfter() {
        String value = getHeaders().get("retry-after");
        if (value == null) {
            return OptionalInt.empty();
        }
        try {
            double seconds = Double.parseDouble(value.strip());
            if (Double.isNaN(seconds)) {
                return OptionalInt.empty();
            }
            return OptionalInt.of((int) Math.max(0, Math.min(Integer.MAX_VALUE, seconds)));
        } catch (NumberFormatException e) {
            return OptionalInt.empty();
        }
    }
}
