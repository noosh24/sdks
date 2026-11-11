package com.noosh24.openapi;

import java.util.Map;
import org.jspecify.annotations.Nullable;

public class NotFoundException extends ApiException {
    public NotFoundException(int status, @Nullable String code, String message, Map<String, String> headers, String body) {
        super(status, code, message, headers, body);
    }
}
