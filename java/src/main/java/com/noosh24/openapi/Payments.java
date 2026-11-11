package com.noosh24.openapi;

import com.noosh24.openapi.model.Payment;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.JsonNode;

public final class Payments extends Resource {
    private static final TypeReference<LinkedHashMap<String, Object>> MAP = new TypeReference<>() {};

    Payments(Noosh24Client client) {
        super(client);
    }

    public Page<Payment> list() {
        return list(ListParams.none());
    }

    public Page<Payment> list(ListParams params) {
        return page("/payments", Payment::from, params.toQuery());
    }

    public PagedIterable<Payment> iterate() {
        return iterate(ListParams.none());
    }

    public PagedIterable<Payment> iterate(ListParams params) {
        return paginate("/payments", Payment::from, params.toQuery(), 100);
    }

    public Payment get(String paymentId) {
        return one("/payments/" + id(paymentId), Payment::from, null);
    }

    public Map<String, Object> zReport() {
        return zReport((String) null);
    }

    public Map<String, Object> zReport(LocalDate date) {
        return zReport(date.toString());
    }

    public Map<String, Object> zReport(@Nullable String date) {
        JsonNode data = client.request("GET", "/reports/z", new Query().add("date", date), null, true).data();
        if (data == null || !data.isObject()) {
            return new LinkedHashMap<>();
        }
        return JsonSupport.MAPPER.convertValue(data, MAP);
    }
}
