package com.noosh24.openapi;

import java.util.Map;
import org.jspecify.annotations.Nullable;

public class TableNotFoundException extends NotFoundException {
    public TableNotFoundException(int status, @Nullable String code, String message, Map<String, String> headers, String body) {
        super(status, code, message, headers, body);
    }
}
