package com.noosh24.openapi;

import static com.noosh24.openapi.MockTransport.body;
import static com.noosh24.openapi.MockTransport.page;
import static com.noosh24.openapi.MockTransport.query;
import static com.noosh24.openapi.Where.where;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.noosh24.openapi.model.Bill;
import com.noosh24.openapi.model.CreateReservationResult;
import com.noosh24.openapi.model.Customer;
import com.noosh24.openapi.model.NewReservation;
import com.noosh24.openapi.model.Order;
import com.noosh24.openapi.model.Payment;
import com.noosh24.openapi.model.PreOrderLine;
import com.noosh24.openapi.model.Product;
import com.noosh24.openapi.model.Reservation;
import com.noosh24.openapi.model.Review;
import com.noosh24.openapi.model.TableAvailability;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;

class ResourcesTest {
    static final String PRODUCT = """
            {
              "id": "0b6f3c1e", "name": "Plov", "category": "Main", "description": "Saffron rice with lamb",
              "price": 14, "available": true, "popular": true, "position": 3, "prepMinutes": 20, "station": "",
              "vatRate": null, "vegetarian": false, "spicy": false, "allergens": ["gluten"], "discountable": true,
              "hasModifiers": true, "image": "https://api.noosh24.com/m/5c1d.jpg", "video": null,
              "modifierGroups": [{"id": "g1", "name": "Size", "required": true, "position": 0,
                "modifiers": [{"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0}]}],
              "translations": {"en": {"name": "Pilaf", "description": "Rice"}, "ru": {"name": "Плов"}}
            }""";

    static final String RESERVATION = """
            {
              "id": "res1", "code": "K7Q2", "status": "%s", "source": "open_api",
              "startsAt": "2026-11-20T15:30:00Z", "endsAt": "2026-11-20T17:30:00.123456789Z",
              "guests": 4, "zone": "Terrace", "table": {"id": "t5", "label": "T5"},
              "guest": {"name": "Aysel", "phone": "+994501234567", "email": null},
              "specialRequest": null, "allergyNote": null, "birthday": false, "childChair": true, "depositPaid": 0,
              "preOrder": [{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": null}],
              "externalRef": "acme-991", "decidedAt": null,
              "createdAt": "2026-11-11T10:00:00.5Z", "updatedAt": "2026-11-11T10:00:00Z"
            }""";

    private final MockTransport http = new MockTransport();
    private final Noosh24Client client = http.client();

    static String data(String json) {
        return "{\"data\": " + json + "}";
    }

    static String reservation(String status) {
        return data(RESERVATION.formatted(status));
    }

    static NewReservation.Builder booking() {
        return NewReservation.builder()
                .date("2026-11-20")
                .time("19:30")
                .guests(4)
                .guestName("Aysel Məmmədova")
                .phone("+994501234567");
    }

    @Test
    void listProductsSendsListParametersAndParsesThePage() {
        http.json(200, page("[" + PRODUCT + "]", 87, 50, 50));

        Page<Product> result = client.menu().listProducts(ProductListParams.builder()
                .limit(50)
                .offset(50)
                .sort("category asc", "price desc")
                .where(where().eq("category", "Chef's").gte("price", 5).eq("available", true))
                .expand(ProductExpand.MODIFIER_GROUPS, ProductExpand.TRANSLATIONS)
                .build());

        assertEquals("/v1/menu/products", http.last().uri().getPath());
        assertEquals(Map.of(
                "limit", List.of("50"),
                "offset", List.of("50"),
                "sort", List.of("category asc", "price desc"),
                "where", List.of("category = 'Chef''s' AND price >= 5 AND available = true"),
                "expand", List.of("modifierGroups", "translations")), query(http.last()));
        assertTrue(http.last().uri().getRawQuery().contains("sort=category%20asc"));
        assertFalse(http.last().uri().getRawQuery().contains("+"));
        assertEquals(87, result.total());
        assertEquals(50, result.limit());
        assertEquals(50, result.offset());
        assertTrue(result.hasMore());
        assertEquals(51, result.nextOffset());
        assertEquals(1, result.size());
        Product product = result.items().get(0);
        assertEquals(14.0, product.price());
        assertNull(product.vatRate());
        assertEquals(20, product.prepMinutes());
        assertEquals(List.of("gluten"), product.allergens());
        assertEquals(2.5, product.modifierGroups().get(0).modifiers().get(0).priceDelta());
        assertEquals("Pilaf", product.translations().get("en").name());
        assertNull(product.translations().get("ru").description());
        assertEquals(JsonSupport.MAPPER.readTree(PRODUCT), product.raw());
    }

    @Test
    void listAcceptsPlainWhereAndSortString() {
        http.json(200, page("[]", 0));

        client.orders().list(ListParams.builder().where("status = 'served'").sort("createdAt desc").build());

        assertEquals(Map.of("sort", List.of("createdAt desc"), "where", List.of("status = 'served'")), query(http.last()));
    }

    @Test
    void listWithoutParametersSendsNoQuery() {
        http.json(200, page("[]", 0));

        Page<Review> result = client.reviews().list();

        assertNull(http.last().uri().getRawQuery());
        assertFalse(result.hasMore());
    }

    @Test
    void iteratorWalksEveryPage() {
        http.json(200, page("[{\"id\": \"c1\"}, {\"id\": \"c2\"}]", 5, 2, 0));
        http.json(200, page("[{\"id\": \"c3\"}, {\"id\": \"c4\"}]", 5, 2, 2));
        http.json(200, page("[{\"id\": \"c5\"}]", 5, 2, 4));

        List<String> ids = client.customers()
                .iterate(ListParams.builder().limit(2).where("createdAt >= '2026-11-01'").build())
                .stream()
                .map(Customer::id)
                .collect(Collectors.toList());

        assertEquals(List.of("c1", "c2", "c3", "c4", "c5"), ids);
        assertEquals(List.of("0", "2", "4"), http.requests.stream().map(r -> query(r).get("offset").get(0)).toList());
        assertEquals(List.of("createdAt >= '2026-11-01'"), query(http.requests.get(2)).get("where"));
        assertEquals(List.of("2"), query(http.requests.get(2)).get("limit"));
    }

    @Test
    void iteratorStartsAtTheGivenOffsetAndWorksInForEach() {
        http.json(200, page("[{\"id\": \"b7\"}]", 8, 50, 7));

        int seen = 0;
        for (Bill bill : client.orders().iterateBills(ListParams.builder().offset(7).build())) {
            assertEquals("b7", bill.id());
            seen++;
        }

        assertEquals(1, seen);
        assertEquals(List.of("7"), query(http.last()).get("offset"));
    }

    @Test
    void iteratorIsLazy() {
        PagedIterable<Payment> payments = client.payments().iterate();
        Iterator<Payment> iterator = payments.iterator();
        assertEquals(0, http.requests.size());

        http.json(200, page("[]", 10, 100, 0));
        assertFalse(iterator.hasNext());
        assertEquals(1, http.requests.size());
    }

    @Test
    void iteratorUsesTheLargestPageEachEndpointAllows() {
        for (int i = 0; i < 5; i++) {
            http.json(200, page("[]", 0));
        }

        client.orders().iterateBills().stream().count();
        client.menu().iterateProducts(ProductListParams.builder().expand(ProductExpand.MODIFIER_GROUPS).build()).stream().count();
        client.stock().iterateMoves().stream().count();
        client.menu().iterateProducts().stream().count();
        client.reservations().iterate().stream().count();

        assertEquals(List.of("50", "50", "100", "100", "100"),
                http.requests.stream().map(r -> query(r).get("limit").get(0)).toList());
    }

    @Test
    void getProductEncodesTheIdAndExpand() {
        http.json(200, data(PRODUCT));

        Product product = client.menu().getProduct("a/b c", ProductExpand.TRANSLATIONS);

        assertEquals("https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations", http.last().uri().toString());
        assertEquals("Plov", product.name());
    }

    @Test
    void emptyIdIsRejected() {
        assertThrows(IllegalArgumentException.class, () -> client.orders().get(""));
        assertThrows(IllegalArgumentException.class, () -> client.reservations().cancel(" "));
        assertEquals(0, http.requests.size());
    }

    @Test
    void categoriesAndStopList() {
        http.json(200, data("{\"items\": [{\"name\": \"Salads\", \"position\": 1, \"products\": 9, \"available\": 8}], \"total\": 1}"));
        http.json(200, data("{\"items\": [{\"id\": \"p9\", \"name\": \"Dolma\", \"category\": \"Main\", \"price\": 9.5}], \"total\": 1}"));

        assertEquals(8, client.menu().listCategories().get(0).available());
        assertEquals("Dolma", client.menu().getStopList().get(0).name());
        assertEquals("/v1/menu/categories", http.requests.get(0).uri().getPath());
        assertEquals("/v1/menu/stop-list", http.last().uri().getPath());
    }

    @Test
    void reservationParsesNestedFieldsAndTimes() {
        http.json(200, reservation("pending"));

        Reservation r = client.reservations().get("res1");

        assertEquals("/v1/reservations/res1", http.last().uri().getPath());
        assertEquals(OffsetDateTime.of(2026, 11, 20, 15, 30, 0, 0, ZoneOffset.UTC), r.startsAt());
        assertEquals(OffsetDateTime.of(2026, 11, 20, 17, 30, 0, 123_456_789, ZoneOffset.UTC), r.endsAt());
        assertEquals(OffsetDateTime.of(2026, 11, 11, 10, 0, 0, 500_000_000, ZoneOffset.UTC), r.createdAt());
        assertNull(r.decidedAt());
        assertEquals("T5", r.table().label());
        assertEquals("+994501234567", r.guest().phone());
        assertNull(r.guest().email());
        assertEquals(2, r.preOrder().get(0).qty());
        assertEquals(0.0, r.depositPaid());
        assertEquals(Boolean.TRUE, r.childChair());
    }

    @Test
    void availability() {
        http.json(200, data("""
                {"startsAt": "2026-11-20T15:30:00Z", "endsAt": "2026-11-20T17:30:00Z", "durationMinutes": 120,
                 "openTime": "10:00", "closeTime": "23:00",
                 "tables": [{"id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": true}]}"""));
        http.json(200, data("{}"));

        TableAvailability result = client.reservations().availability(LocalDate.of(2026, 11, 20), "19:30", 4);
        client.reservations().availability("2026-11-21", "12:00");

        assertEquals("/v1/reservations/availability", http.requests.get(0).uri().getPath());
        assertEquals(Map.of("date", List.of("2026-11-20"), "time", List.of("19:30"), "guests", List.of("4")),
                query(http.requests.get(0)));
        assertEquals(Map.of("date", List.of("2026-11-21"), "time", List.of("12:00")), query(http.last()));
        assertEquals(120, result.durationMinutes());
        assertEquals(Boolean.TRUE, result.tables().get(0).free());
    }

    @Test
    void createReservationPostsJsonAndReportsCreated() {
        http.json(201, reservation("pending"));

        CreateReservationResult result = client.reservations().create(NewReservation.builder()
                .date(LocalDate.of(2026, 11, 20))
                .time("19:30")
                .guests(4)
                .guestName("Aysel Məmmədova")
                .phone("+994501234567")
                .childChair(true)
                .addPreOrder(new PreOrderLine("p1", 2))
                .addPreOrder("p2", 1, "no onion")
                .externalRef("acme-991")
                .build());

        HttpTransport.Request request = http.last();
        assertEquals("POST", request.method());
        assertEquals("https://open-api.noosh24.com/v1/reservations", request.uri().toString());
        assertEquals("application/json", request.headers().get("Content-Type"));
        assertEquals(JsonSupport.MAPPER.readTree("""
                {"date": "2026-11-20", "time": "19:30", "guests": 4, "guestName": "Aysel Məmmədova",
                 "phone": "+994501234567", "childChair": true,
                 "preOrder": [{"itemId": "p1", "qty": 2}, {"itemId": "p2", "qty": 1, "note": "no onion"}],
                 "externalRef": "acme-991"}"""), body(request));
        assertTrue(request.bodyAsString().contains("Məmmədova"));
        assertTrue(new String(request.body(), StandardCharsets.UTF_8).contains("Məmmədova"));
        assertTrue(result.created());
        assertEquals("K7Q2", result.reservation().code());
    }

    @Test
    void createWithAllOptionalFields() {
        http.json(201, data("{\"id\": \"r2\"}"));

        client.reservations().create(booking()
                .email("a@example.com")
                .tableId("t5")
                .zone("Terrace")
                .specialRequest("Window")
                .allergyNote("Nuts")
                .birthday(false)
                .preOrder(List.of())
                .build());

        JsonNode sent = body(http.last());
        assertEquals("a@example.com", sent.get("email").stringValue());
        assertEquals("t5", sent.get("tableId").stringValue());
        assertEquals("Terrace", sent.get("zone").stringValue());
        assertEquals("Window", sent.get("specialRequest").stringValue());
        assertEquals("Nuts", sent.get("allergyNote").stringValue());
        assertFalse(sent.get("birthday").booleanValue());
        assertEquals(0, sent.get("preOrder").size());
        assertFalse(sent.has("childChair"));
        assertFalse(sent.has("externalRef"));
    }

    @Test
    void newReservationNeedsTheRequiredFields() {
        assertThrows(IllegalArgumentException.class, () -> NewReservation.builder().date("2026-11-20").build());
        assertThrows(IllegalArgumentException.class, () -> booking().phone(" ").build());
    }

    @Test
    void createWithKnownExternalRefReturnsTheExistingBooking() {
        http.json(200, reservation("pending"));

        CreateReservationResult result = client.reservations().create(booking().externalRef("acme-991").build());

        assertFalse(result.created());
        assertEquals("res1", result.reservation().id());
    }

    @Test
    void createWithExternalRefIsRetried() {
        http.json(503, "{\"error\": \"temporarily_unavailable\"}", Map.of("Retry-After", "0"));
        http.json(201, reservation("pending"));

        CreateReservationResult result = client.reservations().create(booking().externalRef("acme-991").build());

        assertTrue(result.created());
        assertEquals(2, http.requests.size());
        assertArrayEquals(http.requests.get(0).body(), http.requests.get(1).body());
    }

    @Test
    void createWithoutExternalRefIsNeverRetried() {
        http.json(503, "{\"error\": \"temporarily_unavailable\"}", Map.of("Retry-After", "0"));

        assertThrows(ServerException.class, () -> client.reservations().create(booking().build()));
        assertEquals(1, http.requests.size());

        http.json(503, "{\"error\": \"temporarily_unavailable\"}", Map.of("Retry-After", "0"));
        assertThrows(ServerException.class, () -> client.reservations().create(booking().externalRef("  ").build()));
        assertEquals(2, http.requests.size());
    }

    @Test
    void tableTaken() {
        http.json(409, "{\"error\": \"table_taken\", \"message\": \"Bu masa seçilən vaxt üçün artıq tutulub\"}");

        TableTakenException error = assertThrows(TableTakenException.class,
                () -> client.reservations().create(booking().tableId("t5").externalRef("x").build()));
        assertTrue(error.getMessage().contains("artıq tutulub"));
        assertEquals(1, http.requests.size());
    }

    @Test
    void cancel() {
        http.json(200, reservation("cancelled"));

        Reservation r = client.reservations().cancel("res1");

        assertEquals("POST", http.last().method());
        assertEquals("https://open-api.noosh24.com/v1/reservations/res1/cancel", http.last().uri().toString());
        assertNull(http.last().body());
        assertFalse(http.last().headers().containsKey("Content-Type"));
        assertEquals("cancelled", r.status());
    }

    @Test
    void ordersBillsPaymentsAndZReport() {
        http.json(200, data("""
                {"id": "o1", "number": "A-12", "dailyNumber": 12, "kind": "delivery", "status": "ready", "subtotal": 30,
                 "items": [{"id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": false}],
                 "delivery": {"status": "accepted", "platform": {"id": "wolt", "name": "Wolt", "ref": "W-1"}, "fee": 2,
                              "acceptedAt": "2026-11-11T09:00:00Z"}}"""));
        http.json(200, data("{\"id\": \"b1\", \"status\": \"paid\", \"orderIds\": [\"o1\", \"o2\"], \"total\": 45.5, \"closedAt\": null}"));
        http.json(200, data("""
                {"id": "pay1", "method": "card", "amount": 20,
                 "card": {"maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"}, "platform": null}"""));
        http.json(200, data("{\"date\": \"2026-11-10\", \"cash\": 120.5}"));
        http.json(200, page("[{\"id\": \"o9\"}]", 1));
        http.json(200, page("[{\"id\": \"b9\"}]", 1));
        http.json(200, page("[{\"id\": \"pay9\"}]", 1));
        http.json(200, data("{\"date\": \"2026-11-11\"}"));

        Order order = client.orders().get("o1");
        Bill bill = client.orders().getBill("b1");
        Payment payment = client.payments().get("pay1");
        Map<String, Object> z = client.payments().zReport("2026-11-10");
        assertEquals(Map.of("date", List.of("2026-11-10")), query(http.last()));
        assertEquals("o9", client.orders().list().items().get(0).id());
        assertEquals("b9", client.orders().listBills().items().get(0).id());
        assertEquals("pay9", client.payments().list().items().get(0).id());
        assertEquals("2026-11-11", client.payments().zReport().get("date"));
        assertNull(http.last().uri().getRawQuery());

        assertEquals("Wolt", order.delivery().platform().name());
        assertEquals(2.0, order.delivery().fee());
        assertEquals(OffsetDateTime.of(2026, 11, 11, 9, 0, 0, 0, ZoneOffset.UTC), order.delivery().acceptedAt());
        assertEquals(12, order.dailyNumber());
        assertEquals(15.0, order.items().get(0).price());
        assertEquals(List.of("o1", "o2"), bill.orderIds());
        assertNull(bill.closedAt());
        assertEquals("4169********1234", payment.card().maskedPan());
        assertNull(payment.platform());
        assertEquals(120.5, z.get("cash"));
        assertEquals(List.of("/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z", "/v1/orders", "/v1/bills",
                "/v1/payments", "/v1/reports/z"), http.requests.stream().map(r -> r.uri().getPath()).toList());
    }

    @Test
    void tablesLoyaltyStockAndReviews() {
        http.json(200, data("{\"items\": [{\"id\": \"t1\", \"label\": \"T1\", \"status\": \"occupied\", \"billTotal\": 42.1}], \"total\": 1}"));
        http.json(200, data("{\"stampsNeeded\": 8, \"earnBy\": \"visit\", \"rewardProductIds\": [\"p1\"]}"));
        http.json(200, page("[{\"id\": \"card1\", \"stamps\": 5, \"lastVisitAt\": null}]", 1, 100, 0));
        http.json(200, page("[{\"id\": \"ing1\", \"name\": \"Rice\", \"stock\": 12, \"byStore\": {\"s1\": 10, \"s2\": 2.5}}]", 1));
        http.json(200, data("{\"items\": [{\"id\": \"s1\", \"name\": \"Main\", \"isDefault\": true, \"stations\": [\"hot\"]}], \"total\": 1}"));
        http.json(200, page("[{\"id\": \"rv1\", \"overall\": 4.5, \"ratings\": {\"food\": 5, \"service\": 4}, \"reply\": null}]", 1));
        http.json(200, page("[{\"id\": \"mv1\", \"qty\": -0.25}]", 1));
        http.json(200, page("[]", 0));
        http.json(200, page("[]", 0));
        http.json(200, page("[]", 0));

        assertEquals(42.1, client.tables().list().get(0).billTotal());
        assertEquals(8, client.loyalty().getProgram().stampsNeeded());
        assertFalse(client.loyalty().listCards().hasMore());
        assertEquals(Map.of("s1", 10.0, "s2", 2.5), client.stock().listIngredients().items().get(0).byStore());
        assertEquals(Boolean.TRUE, client.stock().listStores().get(0).isDefault());
        Review review = client.reviews().list().items().get(0);
        assertEquals(5.0, review.ratings().food());
        assertNull(review.ratings().price());
        assertEquals(-0.25, client.stock().listMoves().items().get(0).qty());
        client.loyalty().iterateCards().stream().count();
        client.stock().iterateIngredients().stream().count();
        client.reviews().iterate().stream().count();
        assertEquals(List.of("/v1/tables", "/v1/loyalty/program", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/stock/stores",
                "/v1/reviews", "/v1/stock/moves", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/reviews"),
                http.requests.stream().map(r -> r.uri().getPath()).toList());
    }

    @Test
    void hallsPath() {
        http.json(200, data("{\"items\": [], \"total\": 0}"));

        assertEquals(List.of(), client.tables().listHalls());
        assertEquals("/v1/halls", http.last().uri().getPath());
    }

    @Test
    void modelsTolerateMissingAndUnknownFields() {
        http.json(201, data("{\"id\": \"res9\", \"code\": \"ZZ11\", \"status\": \"pending\", \"brandNew\": 1}"));

        CreateReservationResult result = client.reservations().create(booking().build());

        assertTrue(result.created());
        assertEquals("ZZ11", result.reservation().code());
        assertNull(result.reservation().guest());
        assertNull(result.reservation().startsAt());
        assertEquals(List.of(), result.reservation().preOrder());
        assertEquals(1, result.reservation().raw().get("brandNew").intValue());
    }

    @Test
    void modelsTolerateWrongTypes() {
        Product product = Product.from(JsonSupport.MAPPER.readTree(
                "{\"price\": \"cheap\", \"allergens\": \"gluten\", \"available\": 1, \"name\": 7, \"modifierGroups\": [1, {\"id\": \"g\"}]}"));

        assertNull(product.price());
        assertEquals(List.of(), product.allergens());
        assertEquals(Boolean.TRUE, product.available());
        assertEquals("7", product.name());
        assertEquals(1, product.modifierGroups().size());
        assertEquals(Map.of(), product.translations());
        assertNull(Product.from(null).id());
    }

    @Test
    void recordsAlsoBindWithJacksonDirectly() {
        Customer customer = JsonSupport.MAPPER.readValue(
                "{\"id\": \"c1\", \"name\": \"Aysel\", \"createdAt\": \"2026-11-11T10:00:00.123456789Z\", \"unknown\": true}",
                Customer.class);

        assertEquals("c1", customer.id());
        assertEquals(123_456_789, customer.createdAt().getNano());
        assertNull(customer.raw());
        assertFalse(JsonSupport.MAPPER.writeValueAsString(customer).contains("raw"));
    }
}
