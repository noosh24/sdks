#include <ranges>

#include "mock.hpp"

using namespace std::chrono;
using namespace std::chrono_literals;
using testing_support::body_of;
using testing_support::ClientTest;
using testing_support::header;
using testing_support::json;
using testing_support::page;
using testing_support::path_of;
using testing_support::query_of;
using testing_support::QueryMap;

static_assert(std::ranges::input_range<noosh24::ItemRange<noosh24::Customer>>);
static_assert(std::input_iterator<noosh24::ItemRange<noosh24::Customer>::iterator>);

namespace {

const json product = json::parse(R"({
  "id": "0b6f3c1e",
  "name": "Plov",
  "category": "Main",
  "description": "Saffron rice with lamb",
  "price": 14,
  "available": true,
  "popular": true,
  "position": 3,
  "prepMinutes": 20,
  "station": "",
  "vatRate": null,
  "vegetarian": false,
  "spicy": false,
  "allergens": ["gluten"],
  "discountable": true,
  "hasModifiers": true,
  "image": "https://api.noosh24.com/m/5c1d.jpg",
  "video": null,
  "modifierGroups": [
    {"id": "g1", "name": "Size", "required": true, "position": 0,
     "modifiers": [{"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0}]}
  ],
  "translations": {"en": {"name": "Pilaf", "description": "Rice"}, "ru": {"name": "Плов"}}
})");

const json reservation = json::parse(R"({
  "id": "res1",
  "code": "K7Q2",
  "status": "pending",
  "source": "open_api",
  "startsAt": "2026-11-20T15:30:00Z",
  "endsAt": "2026-11-20T17:30:00.123456789Z",
  "guests": 4,
  "zone": "Terrace",
  "table": {"id": "t5", "label": "T5"},
  "guest": {"name": "Aysel", "phone": "+994501234567", "email": null},
  "specialRequest": null,
  "allergyNote": null,
  "birthday": false,
  "childChair": true,
  "depositPaid": 0,
  "preOrder": [{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": null}],
  "externalRef": "acme-991",
  "decidedAt": null,
  "createdAt": "2026-11-11T10:00:00.5Z",
  "updatedAt": "2026-11-11T14:00:00+04:00"
})");

noosh24::NewReservation booking(std::optional<std::string> external_ref = std::nullopt)
{
    return noosh24::NewReservation{
        .date = "2026-11-20",
        .time = "19:30",
        .guests = 4,
        .guest_name = "Aysel Məmmədova",
        .phone = "+994501234567",
        .external_ref = std::move(external_ref),
    };
}

json data(json value)
{
    return json{{"data", std::move(value)}};
}

}

TEST_F(ClientTest, ListProductsSendsListParametersAndParsesThePage)
{
    auto client = make();
    http->reply(200, page(json::array({product}), 87, 50, 50));

    auto result = client.menu().list_products({
        .limit = 50,
        .offset = 50,
        .sort = {"category asc", "price desc"},
        .where = noosh24::where().eq("category", "Chef's").gte("price", 5).eq("available", true),
        .expand = {"modifierGroups", "translations"},
    });

    EXPECT_EQ(path_of(http->last().url), "/v1/menu/products");
    EXPECT_EQ(query_of(http->last().url), (QueryMap{
                                              {"limit", {"50"}},
                                              {"offset", {"50"}},
                                              {"sort", {"category asc", "price desc"}},
                                              {"where", {"category = 'Chef''s' AND price >= 5 AND available = true"}},
                                              {"expand", {"modifierGroups", "translations"}},
                                          }));
    EXPECT_NE(http->last().url.find("where=category%20%3D%20%27Chef%27%27s%27%20AND"), std::string::npos);
    EXPECT_EQ(result.total, 87);
    EXPECT_EQ(result.limit, 50);
    EXPECT_EQ(result.offset, 50);
    EXPECT_TRUE(result.has_more());
    EXPECT_EQ(result.next_offset(), 51);
    ASSERT_EQ(result.size(), 1U);
    const auto& p = result.items[0];
    EXPECT_EQ(p.price, 14.0);
    EXPECT_FALSE(p.vat_rate.has_value());
    EXPECT_EQ(p.prep_minutes, 20);
    EXPECT_EQ(p.station, "");
    EXPECT_FALSE(p.video.has_value());
    EXPECT_EQ(p.allergens, (std::vector<std::string>{"gluten"}));
    EXPECT_EQ(p.modifier_groups.at(0).modifiers.at(0).price_delta, 2.5);
    EXPECT_EQ(p.translations.at("en").name, "Pilaf");
    EXPECT_FALSE(p.translations.at("ru").description.has_value());
    EXPECT_EQ(p.raw, product);
}

TEST_F(ClientTest, ListAcceptsPlainWhereAndSingleSort)
{
    auto client = make();
    http->reply(200, page(json::array(), 0));

    (void)client.orders().list({.sort = {"createdAt desc"}, .where = "status = 'served'"});

    EXPECT_EQ(query_of(http->last().url), (QueryMap{{"sort", {"createdAt desc"}}, {"where", {"status = 'served'"}}}));
}

TEST_F(ClientTest, IteratorWalksEveryPage)
{
    auto client = make();
    http->reply(200, page({{{"id", "c1"}}, {{"id", "c2"}}}, 5, 2, 0));
    http->reply(200, page({{{"id", "c3"}}, {{"id", "c4"}}}, 5, 2, 2));
    http->reply(200, page({{{"id", "c5"}}}, 5, 2, 4));

    std::vector<std::string> ids;
    for (const auto& customer : client.customers().iterate({.limit = 2, .where = "createdAt >= '2026-11-01'"})) {
        ids.push_back(customer.id.value_or(""));
    }

    EXPECT_EQ(ids, (std::vector<std::string>{"c1", "c2", "c3", "c4", "c5"}));
    std::vector<std::string> offsets;
    for (const auto& request : http->requests) {
        offsets.push_back(query_of(request.url).at("offset").at(0));
    }
    EXPECT_EQ(offsets, (std::vector<std::string>{"0", "2", "4"}));
    EXPECT_EQ(query_of(http->requests[2].url).at("where"), (std::vector<std::string>{"createdAt >= '2026-11-01'"}));
}

TEST_F(ClientTest, IteratorStartsAtTheGivenOffset)
{
    auto client = make();
    http->reply(200, page({{{"id", "r7"}}}, 8, 100, 7));

    auto range = client.reviews().iterate({.offset = 7});
    auto count = std::ranges::distance(range.begin(), range.end());

    EXPECT_EQ(count, 1);
    EXPECT_EQ(query_of(http->last().url), (QueryMap{{"limit", {"100"}}, {"offset", {"7"}}}));
}

TEST_F(ClientTest, IteratorIsLazy)
{
    auto client = make();
    auto range = client.payments().iterate();
    EXPECT_TRUE(http->requests.empty());

    http->reply(200, page(json::array(), 10, 100, 0));
    std::size_t count = 0;
    for (const auto& payment : range) {
        (void)payment;
        ++count;
    }
    EXPECT_EQ(count, 0U);
    EXPECT_EQ(http->requests.size(), 1U);
}

TEST_F(ClientTest, IteratorUsesTheLargestPageEachEndpointAllows)
{
    auto client = make();
    for (int i = 0; i < 4; ++i) {
        http->reply(200, page(json::array(), 0));
    }

    for (const auto& item : client.orders().iterate_bills()) {
        (void)item;
    }
    for (const auto& item : client.menu().iterate_products({.expand = {"modifierGroups"}})) {
        (void)item;
    }
    for (const auto& item : client.stock().iterate_moves()) {
        (void)item;
    }
    for (const auto& item : client.menu().iterate_products()) {
        (void)item;
    }

    std::vector<std::string> limits;
    for (const auto& request : http->requests) {
        limits.push_back(query_of(request.url).at("limit").at(0));
    }
    EXPECT_EQ(limits, (std::vector<std::string>{"50", "50", "100", "100"}));
}

TEST_F(ClientTest, GetProductEncodesTheIdAndExpand)
{
    auto client = make();
    http->reply(200, data(product));

    auto p = client.menu().get_product("a/b c", {"translations"});

    EXPECT_EQ(http->last().url, "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations");
    EXPECT_EQ(p.name, "Plov");
}

TEST_F(ClientTest, EmptyIdIsRejected)
{
    auto client = make();
    EXPECT_THROW((void)client.orders().get(""), std::invalid_argument);
    EXPECT_THROW((void)client.reservations().cancel("  "), std::invalid_argument);
    EXPECT_TRUE(http->requests.empty());
}

TEST_F(ClientTest, CategoriesAndStopList)
{
    auto client = make();
    http->reply(200, data({{"items", {{{"name", "Salads"}, {"position", 1}, {"products", 9}, {"available", 8}}}},
                           {"total", 1}}));
    http->reply(200,
                data({{"items", {{{"id", "p9"}, {"name", "Dolma"}, {"category", "Main"}, {"price", 9.5}}}}, {"total", 1}}));

    EXPECT_EQ(client.menu().list_categories().at(0).available, 8);
    EXPECT_EQ(client.menu().get_stop_list().at(0).name, "Dolma");
    EXPECT_EQ(path_of(http->requests[0].url), "/v1/menu/categories");
    EXPECT_EQ(path_of(http->last().url), "/v1/menu/stop-list");
}

TEST_F(ClientTest, ReservationParsesNestedFieldsAndTimes)
{
    auto client = make();
    http->reply(200, data(reservation));

    auto r = client.reservations().get("res1");

    EXPECT_EQ(path_of(http->last().url), "/v1/reservations/res1");
    EXPECT_EQ(r.starts_at, noosh24::Timestamp{sys_days{2026y / November / 20} + 15h + 30min});
    EXPECT_EQ(r.ends_at, noosh24::Timestamp{sys_days{2026y / November / 20} + 17h + 30min + 123456us});
    EXPECT_EQ(r.created_at, noosh24::Timestamp{sys_days{2026y / November / 11} + 10h + 500ms});
    EXPECT_EQ(r.updated_at, noosh24::Timestamp{sys_days{2026y / November / 11} + 10h});
    EXPECT_FALSE(r.decided_at.has_value());
    EXPECT_EQ(r.table->label, "T5");
    EXPECT_EQ(r.guest->phone, "+994501234567");
    EXPECT_FALSE(r.guest->email.has_value());
    EXPECT_EQ(r.pre_order.at(0).qty, 2);
    EXPECT_FALSE(r.pre_order.at(0).note.has_value());
    EXPECT_EQ(r.deposit_paid, 0.0);
    EXPECT_EQ(r.child_chair, true);
}

TEST_F(ClientTest, Availability)
{
    auto client = make();
    http->reply(200, data({{"startsAt", "2026-11-20T15:30:00Z"},
                           {"endsAt", "2026-11-20T17:30:00Z"},
                           {"durationMinutes", 120},
                           {"openTime", "10:00"},
                           {"closeTime", "23:00"},
                           {"tables",
                            {{{"id", "t5"},
                              {"label", "T5"},
                              {"hallId", "h1"},
                              {"zone", "Terrace"},
                              {"seats", 4},
                              {"free", true}}}}}));

    auto result = client.reservations().availability(2026y / November / 20, "19:30", 4);

    EXPECT_EQ(path_of(http->last().url), "/v1/reservations/availability");
    EXPECT_EQ(query_of(http->last().url), (QueryMap{{"date", {"2026-11-20"}}, {"time", {"19:30"}}, {"guests", {"4"}}}));
    EXPECT_EQ(result.duration_minutes, 120);
    EXPECT_EQ(result.tables.at(0).free, true);

    http->reply(200, data(json::object()));
    (void)client.reservations().availability("2026-11-21", "20:00");
    EXPECT_EQ(query_of(http->last().url), (QueryMap{{"date", {"2026-11-21"}}, {"time", {"20:00"}}}));
}

TEST_F(ClientTest, CreateReservationPostsJsonAndReportsCreated)
{
    auto client = make();
    http->reply(201, data(reservation));

    auto result = client.reservations().create({
        .date = 2026y / November / 20,
        .time = "19:30",
        .guests = 4,
        .guest_name = "Aysel Məmmədova",
        .phone = "+994501234567",
        .child_chair = true,
        .pre_order = {{.item_id = "p1", .qty = 2}, {.item_id = "p2", .qty = 1, .note = "no onion"}},
        .external_ref = "acme-991",
    });

    const auto& request = http->last();
    EXPECT_EQ(request.method, "POST");
    EXPECT_EQ(request.url, "https://open-api.noosh24.com/v1/reservations");
    EXPECT_EQ(header(request, "content-type"), "application/json");
    EXPECT_EQ(body_of(request), json::parse(R"({
        "date": "2026-11-20",
        "time": "19:30",
        "guests": 4,
        "guestName": "Aysel Məmmədova",
        "phone": "+994501234567",
        "childChair": true,
        "externalRef": "acme-991",
        "preOrder": [{"itemId": "p1", "qty": 2}, {"itemId": "p2", "qty": 1, "note": "no onion"}]
    })"));
    EXPECT_NE(request.body->find("Məmmədova"), std::string::npos);
    EXPECT_TRUE(result.created);
    EXPECT_EQ(result.reservation.code, "K7Q2");
}

TEST_F(ClientTest, CreateWithKnownExternalRefReturnsTheExistingBooking)
{
    auto client = make();
    http->reply(200, data(reservation));

    auto result = client.reservations().create(booking("acme-991"));

    EXPECT_FALSE(result.created);
    EXPECT_EQ(result.reservation.id, "res1");
}

TEST_F(ClientTest, CreateWithExternalRefIsRetried)
{
    auto client = make();
    http->reply(503, {{"error", "temporarily_unavailable"}}, {{"Retry-After", "0"}});
    http->reply(201, data(reservation));

    auto result = client.reservations().create(booking("acme-991"));

    EXPECT_TRUE(result.created);
    ASSERT_EQ(http->requests.size(), 2U);
    EXPECT_EQ(http->requests[0].body, http->requests[1].body);
    EXPECT_EQ(sleeps, (std::vector<std::chrono::milliseconds>{0ms}));
}

TEST_F(ClientTest, CreateWithoutExternalRefIsNeverRetried)
{
    auto client = make();
    http->reply(503, {{"error", "temporarily_unavailable"}}, {{"Retry-After", "0"}});

    EXPECT_THROW((void)client.reservations().create(booking()), noosh24::ServerError);
    EXPECT_EQ(http->requests.size(), 1U);

    http->fail(noosh24::ConnectionError("connection reset"));
    EXPECT_THROW((void)client.reservations().create(booking("   ")), noosh24::ConnectionError);
    EXPECT_EQ(http->requests.size(), 2U);
}

TEST_F(ClientTest, TableTaken)
{
    auto client = make();
    http->reply(409, {{"error", "table_taken"}, {"message", "Bu masa seçilən vaxt üçün artıq tutulub"}});

    auto request = booking("x");
    request.table_id = "t5";
    try {
        (void)client.reservations().create(request);
        FAIL() << "expected TableTakenError";
    } catch (const noosh24::TableTakenError& error) {
        EXPECT_NE(error.message().find("artıq tutulub"), std::string::npos);
    }
    EXPECT_EQ(body_of(http->last()).at("tableId"), "t5");
}

TEST_F(ClientTest, Cancel)
{
    auto client = make();
    auto cancelled = reservation;
    cancelled["status"] = "cancelled";
    http->reply(200, data(cancelled));

    auto r = client.reservations().cancel("res1");

    EXPECT_EQ(http->last().method, "POST");
    EXPECT_EQ(http->last().url, "https://open-api.noosh24.com/v1/reservations/res1/cancel");
    EXPECT_FALSE(http->last().body.has_value());
    EXPECT_EQ(r.status, "cancelled");
}

TEST_F(ClientTest, OrdersBillsPaymentsAndZReport)
{
    auto client = make();
    http->reply(200, data({{"id", "o1"},
                           {"number", "A-12"},
                           {"dailyNumber", 12},
                           {"kind", "delivery"},
                           {"status", "ready"},
                           {"subtotal", 30},
                           {"items",
                            {{{"id", "i1"}, {"productId", "p1"}, {"name", "Plov"}, {"qty", 2}, {"price", 15},
                              {"comp", false}}}},
                           {"delivery",
                            {{"status", "accepted"},
                             {"platform", {{"id", "wolt"}, {"name", "Wolt"}, {"ref", "W-1"}}},
                             {"fee", 2},
                             {"acceptedAt", "2026-11-11T09:00:00Z"}}}}));
    http->reply(200,
                data({{"id", "b1"}, {"status", "paid"}, {"orderIds", {"o1", "o2"}}, {"total", 45.5}, {"closedAt", nullptr}}));
    http->reply(200, data({{"id", "pay1"},
                           {"method", "card"},
                           {"amount", 20},
                           {"card", {{"maskedPan", "4169********1234"}, {"scheme", "visa"}, {"bank", "Kapital"}}},
                           {"platform", nullptr}}));
    http->reply(200, data({{"date", "2026-11-10"}, {"cash", 120.5}}));

    auto order = client.orders().get("o1");
    auto bill = client.orders().get_bill("b1");
    auto payment = client.payments().get("pay1");
    auto z = client.payments().z_report("2026-11-10");

    EXPECT_EQ(order.delivery->platform->name, "Wolt");
    EXPECT_EQ(order.delivery->fee, 2.0);
    EXPECT_EQ(order.delivery->accepted_at, noosh24::Timestamp{sys_days{2026y / November / 11} + 9h});
    EXPECT_EQ(order.items.at(0).price, 15.0);
    EXPECT_EQ(order.daily_number, 12);
    EXPECT_EQ(bill.order_ids, (std::vector<std::string>{"o1", "o2"}));
    EXPECT_FALSE(bill.closed_at.has_value());
    EXPECT_EQ(bill.total, 45.5);
    EXPECT_EQ(payment.card->masked_pan, "4169********1234");
    EXPECT_FALSE(payment.platform.has_value());
    EXPECT_EQ(z.at("cash"), 120.5);
    EXPECT_EQ(query_of(http->last().url), (QueryMap{{"date", {"2026-11-10"}}}));
    std::vector<std::string> paths;
    for (const auto& request : http->requests) {
        paths.push_back(path_of(request.url));
    }
    EXPECT_EQ(paths, (std::vector<std::string>{"/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"}));

    http->reply(200, data({{"date", "2026-11-11"}}));
    (void)client.payments().z_report();
    EXPECT_EQ(http->last().url, "https://open-api.noosh24.com/v1/reports/z");
}

TEST_F(ClientTest, ListsOfOrdersBillsPaymentsAndReservations)
{
    auto client = make();
    for (int i = 0; i < 4; ++i) {
        http->reply(200, page(json::array(), 0));
    }

    (void)client.orders().list();
    (void)client.orders().list_bills({.limit = 10});
    (void)client.payments().list();
    (void)client.reservations().list({.sort = {"startsAt asc"}});

    std::vector<std::string> paths;
    for (const auto& request : http->requests) {
        paths.push_back(path_of(request.url));
    }
    EXPECT_EQ(paths, (std::vector<std::string>{"/v1/orders", "/v1/bills", "/v1/payments", "/v1/reservations"}));
    EXPECT_EQ(http->requests[1].url, "https://open-api.noosh24.com/v1/bills?limit=10");
}

TEST_F(ClientTest, TablesLoyaltyStockAndReviews)
{
    auto client = make();
    http->reply(200, data({{"items", {{{"id", "t1"}, {"label", "T1"}, {"status", "occupied"}, {"billTotal", 42.1}}}},
                           {"total", 1}}));
    http->reply(200, data({{"stampsNeeded", 8}, {"earnBy", "visit"}, {"rewardProductIds", {"p1"}}}));
    http->reply(200, page({{{"id", "card1"}, {"stamps", 5}, {"lastVisitAt", nullptr}}}, 1, 100));
    http->reply(200, page({{{"id", "ing1"}, {"name", "Rice"}, {"stock", 12}, {"byStore", {{"s1", 10}, {"s2", 2.5}}}}}, 1));
    http->reply(200, data({{"items", {{{"id", "s1"}, {"name", "Main"}, {"isDefault", true}, {"stations", {"hot"}}}}},
                           {"total", 1}}));
    http->reply(200, page({{{"id", "rv1"}, {"overall", 4.5}, {"ratings", {{"food", 5}, {"service", 4}}}, {"reply", nullptr}}},
                          1));
    http->reply(200, page(json::array(), 0));
    http->reply(200, page(json::array(), 0));
    http->reply(200, page(json::array(), 0));

    EXPECT_EQ(client.tables().list().at(0).bill_total, 42.1);
    EXPECT_EQ(client.loyalty().get_program().stamps_needed, 8);
    EXPECT_FALSE(client.loyalty().list_cards().has_more());
    EXPECT_EQ(client.stock().list_ingredients().items.at(0).by_store,
              (std::map<std::string, double>{{"s1", 10.0}, {"s2", 2.5}}));
    EXPECT_EQ(client.stock().list_stores().at(0).is_default, true);
    auto review = client.reviews().list().items.at(0);
    EXPECT_EQ(review.ratings->food, 5.0);
    EXPECT_FALSE(review.ratings->price.has_value());
    for (const auto& card : client.loyalty().iterate_cards()) {
        (void)card;
    }
    for (const auto& ingredient : client.stock().iterate_ingredients()) {
        (void)ingredient;
    }
    (void)client.stock().list_moves();

    std::vector<std::string> paths;
    for (const auto& request : http->requests) {
        paths.push_back(path_of(request.url));
    }
    EXPECT_EQ(paths, (std::vector<std::string>{"/v1/tables", "/v1/loyalty/program", "/v1/loyalty/cards",
                                               "/v1/stock/ingredients", "/v1/stock/stores", "/v1/reviews",
                                               "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/stock/moves"}));
}

TEST_F(ClientTest, HallsAndCustomers)
{
    auto client = make();
    http->reply(200, data({{"items", {{{"id", "h1"}, {"name", "Main"}, {"position", 1}}}}, {"total", 1}}));
    http->reply(200, data({{"id", "c/1"}, {"name", "Aysel"}, {"createdAt", "2026-11-01T00:00:00Z"}}));
    http->reply(200, page({{{"id", "c1"}}}, 1));

    EXPECT_EQ(client.tables().list_halls().at(0).position, 1);
    EXPECT_EQ(client.customers().get("c/1").created_at, noosh24::Timestamp{sys_days{2026y / November / 1}});
    EXPECT_EQ(client.customers().list().items.at(0).id, "c1");
    EXPECT_EQ(path_of(http->requests[0].url), "/v1/halls");
    EXPECT_EQ(http->requests[1].url, "https://open-api.noosh24.com/v1/customers/c%2F1");
    EXPECT_EQ(path_of(http->requests[2].url), "/v1/customers");
}

TEST_F(ClientTest, ModelsTolerateMissingAndUnknownFields)
{
    auto client = make();
    http->reply(201, data({{"id", "res9"}, {"code", "ZZ11"}, {"status", "pending"}, {"brandNew", 1}}));

    auto result = client.reservations().create(booking());

    EXPECT_TRUE(result.created);
    EXPECT_EQ(result.reservation.code, "ZZ11");
    EXPECT_FALSE(result.reservation.guest.has_value());
    EXPECT_FALSE(result.reservation.starts_at.has_value());
    EXPECT_TRUE(result.reservation.pre_order.empty());
    EXPECT_EQ(result.reservation.raw.at("brandNew"), 1);
}

TEST_F(ClientTest, ModelsIgnoreWrongTypes)
{
    auto client = make();
    http->reply(200, data({{"id", 42},
                           {"price", "14"},
                           {"available", 1},
                           {"position", 3.9},
                           {"allergens", {"gluten", nullptr, 7, json::object()}},
                           {"modifierGroups", {1, {{"id", "g1"}}}},
                           {"translations", "none"}}));

    auto p = client.menu().get_product("p1");

    EXPECT_EQ(p.id, "42");
    EXPECT_FALSE(p.price.has_value());
    EXPECT_EQ(p.available, true);
    EXPECT_EQ(p.position, 3);
    EXPECT_EQ(p.allergens, (std::vector<std::string>{"gluten", "7"}));
    ASSERT_EQ(p.modifier_groups.size(), 1U);
    EXPECT_EQ(p.modifier_groups[0].id, "g1");
    EXPECT_TRUE(p.translations.empty());
}

TEST_F(ClientTest, TimestampsWithOffsetsAndBadValues)
{
    auto client = make();
    http->reply(200, page({{{"createdAt", "2026-11-11T14:00:00.1+04:00"},
                            {"updatedAt", "not a date"},
                            {"lastVisitAt", "2026-11-10"}}},
                          1));

    auto cards = client.loyalty().list_cards();

    const auto& c = cards.items.at(0);
    EXPECT_EQ(c.created_at, noosh24::Timestamp{sys_days{2026y / November / 11} + 10h + 100ms});
    EXPECT_FALSE(c.updated_at.has_value());
    EXPECT_EQ(c.last_visit_at, noosh24::Timestamp{sys_days{2026y / November / 10}});
}
