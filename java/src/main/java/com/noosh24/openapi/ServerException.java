package com.noosh24.openapi;

import java.util.Map;
import org.jspecify.annotations.Nullable;

public class ServerException extends ApiException {
    public ServerException(int status, @Nullable String code, String message, Map<String, String> headers, String body) {
        super(status, code, message, headers, body);
    }
}
