package com.noosh24.openapi;

import org.jspecify.annotations.Nullable;

public class ApiConnectionException extends Noosh24Exception {
    public ApiConnectionException(String message, @Nullable Throwable cause) {
        super(message, cause);
    }
}
