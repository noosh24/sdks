package com.noosh24.openapi;

import org.jspecify.annotations.Nullable;

public class ApiTimeoutException extends ApiConnectionException {
    public ApiTimeoutException(String message, @Nullable Throwable cause) {
        super(message, cause);
    }
}
