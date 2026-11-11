package com.noosh24.openapi;

import com.noosh24.openapi.model.Customer;

public final class Customers extends Resource {
    Customers(Noosh24Client client) {
        super(client);
    }

    public Page<Customer> list() {
        return list(ListParams.none());
    }

    public Page<Customer> list(ListParams params) {
        return page("/customers", Customer::from, params.toQuery());
    }

    public PagedIterable<Customer> iterate() {
        return iterate(ListParams.none());
    }

    public PagedIterable<Customer> iterate(ListParams params) {
        return paginate("/customers", Customer::from, params.toQuery(), 100);
    }

    public Customer get(String customerId) {
        return one("/customers/" + id(customerId), Customer::from, null);
    }
}
