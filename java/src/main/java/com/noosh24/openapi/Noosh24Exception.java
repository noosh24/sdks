package com.noosh24.openapi;

import org.jspecify.annotations.Nullable;

public class Noosh24Exception extends RuntimeException {
    public Noosh24Exception(String message) {
        super(message);
    }

    public Noosh24Exception(String message, @Nullable Throwable cause) {
        super(message, cause);
    }
}
