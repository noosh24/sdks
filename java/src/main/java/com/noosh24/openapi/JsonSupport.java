package com.noosh24.openapi;

import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

final class JsonSupport {
    static final ObjectMapper MAPPER = JsonMapper.builder().build();

    private JsonSupport() {}
}
