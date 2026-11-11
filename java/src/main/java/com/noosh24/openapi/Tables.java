package com.noosh24.openapi;

import com.noosh24.openapi.model.Hall;
import com.noosh24.openapi.model.Table;
import java.util.List;

public final class Tables extends Resource {
    Tables(Noosh24Client client) {
        super(client);
    }

    public List<Table> list() {
        return all("/tables", Table::from);
    }

    public List<Hall> listHalls() {
        return all("/halls", Hall::from);
    }
}
