# frozen_string_literal: true

require_relative "test_helper"

class TestResources < Minitest::Test
  include ClientTest

  PRODUCT = {
    "id" => "0b6f3c1e",
    "name" => "Plov",
    "category" => "Main",
    "description" => "Saffron rice with lamb",
    "price" => 14,
    "available" => true,
    "popular" => true,
    "position" => 3,
    "prepMinutes" => 20,
    "station" => "",
    "vatRate" => nil,
    "vegetarian" => false,
    "spicy" => false,
    "allergens" => ["gluten"],
    "discountable" => true,
    "hasModifiers" => true,
    "image" => "https://api.noosh24.com/m/5c1d.jpg",
    "video" => nil,
    "modifierGroups" => [
      {
        "id" => "g1", "name" => "Size", "required" => true, "position" => 0,
        "modifiers" => [{ "id" => "m1", "name" => "Large", "priceDelta" => 2.5, "position" => 0 }]
      }
    ],
    "translations" => { "en" => { "name" => "Pilaf", "description" => "Rice" }, "ru" => { "name" => "Плов" } }
  }.freeze

  RESERVATION = {
    "id" => "res1",
    "code" => "K7Q2",
    "status" => "pending",
    "source" => "open_api",
    "startsAt" => "2026-11-20T15:30:00Z",
    "endsAt" => "2026-11-20T17:30:00.123456789Z",
    "guests" => 4,
    "zone" => "Terrace",
    "table" => { "id" => "t5", "label" => "T5" },
    "guest" => { "name" => "Aysel", "phone" => "+994501234567", "email" => nil },
    "specialRequest" => nil,
    "allergyNote" => nil,
    "birthday" => false,
    "childChair" => true,
    "depositPaid" => 0,
    "preOrder" => [{ "productId" => "p1", "name" => "Plov", "price" => 14.5, "qty" => 2, "note" => nil }],
    "externalRef" => "acme-991",
    "decidedAt" => nil,
    "createdAt" => "2026-11-11T10:00:00.5Z",
    "updatedAt" => "2026-11-11T10:00:00Z"
  }.freeze

  BOOKING = {
    date: "2026-11-20", time: "19:30", guests: 4, guest_name: "Aysel Məmmədova", phone: "+994501234567"
  }.freeze

  def test_list_products_sends_list_parameters_and_parses_the_page
    @http.json(200, page([PRODUCT], 87, 50, 50))

    result = client.menu.list_products(
      limit: 50,
      offset: 50,
      sort: ["category asc", "price desc"],
      where: Noosh24.where.eq("category", "Chef's").gte("price", 5).eq("available", true),
      expand: %w[modifierGroups translations]
    )

    assert_equal "/v1/menu/products", path(@http.last)
    assert_includes @http.last.url, "where=category%20%3D%20%27Chef%27%27s%27%20AND%20price"
    assert_equal({
                   "limit" => ["50"],
                   "offset" => ["50"],
                   "sort" => ["category asc", "price desc"],
                   "where" => ["category = 'Chef''s' AND price >= 5 AND available = true"],
                   "expand" => %w[modifierGroups translations]
                 }, query(@http.last))
    assert_equal [87, 50, 50, true, 1], [result.total, result.limit, result.offset, result.has_more?, result.size]
    assert_equal 51, result.next_offset
    product = result.items.first

    assert_instance_of Noosh24::Product, product
    assert_predicate product, :frozen?
    assert_instance_of Float, product.price
    assert_in_delta 14.0, product.price
    assert_nil product.vat_rate
    assert_equal 20, product.prep_minutes
    assert_equal ["gluten"], product.allergens
    assert_in_delta 2.5, product.modifier_groups.first.modifiers.first.price_delta
    assert_equal "Pilaf", product.translations["en"].name
    assert_nil product.translations["ru"].description
    assert_equal PRODUCT, product.raw
    assert_equal ["Plov"], result.map(&:name)
  end

  def test_list_accepts_plain_where_and_sort_string
    @http.json(200, page([], 0))

    client.orders.list(where: "status = 'served'", sort: "createdAt desc")

    assert_equal({ "sort" => ["createdAt desc"], "where" => ["status = 'served'"] }, query(@http.last))
  end

  def test_unknown_list_parameter_is_rejected
    assert_raises(ArgumentError) { client.reviews.list(page: 2) }
  end

  def test_iterator_walks_every_page
    @http.json(200, page([{ id: "c1" }, { id: "c2" }], 5, 2, 0))
    @http.json(200, page([{ id: "c3" }, { id: "c4" }], 5, 2, 2))
    @http.json(200, page([{ id: "c5" }], 5, 2, 4))

    ids = client.customers.iterate(limit: 2, where: "createdAt >= '2026-11-01'").map(&:id)

    assert_equal %w[c1 c2 c3 c4 c5], ids
    assert_equal(%w[0 2 4], @http.requests.map { |r| query(r)["offset"].first })
    assert_equal ["createdAt >= '2026-11-01'"], query(@http.requests[2])["where"]
  end

  def test_iterator_takes_a_block_and_a_start_offset
    @http.json(200, page([{ id: "c3" }], 3, 100, 2))
    seen = []

    result = client.customers.iterate(offset: 2) { |customer| seen << customer.id }

    assert_nil result
    assert_equal ["c3"], seen
    assert_equal({ "limit" => ["100"], "offset" => ["2"] }, query(@http.last))
  end

  def test_iterator_is_lazy
    iterator = client.payments.iterate

    assert_instance_of Enumerator, iterator
    assert_empty @http.requests
    @http.json(200, page([], 10, 100, 0))

    assert_equal [], iterator.to_a
    assert_equal 1, @http.requests.size
  end

  def test_iterator_stops_fetching_when_the_caller_stops
    @http.json(200, page([{ id: "c1" }, { id: "c2" }], 6, 2, 0))

    assert_equal ["c1"], client.customers.iterate(limit: 2).first(1).map(&:id)
    assert_equal 1, @http.requests.size
  end

  def test_iterator_uses_the_largest_page_each_endpoint_allows
    3.times { @http.json(200, page([], 0)) }

    client.orders.iterate_bills.to_a
    client.menu.iterate_products(expand: "modifierGroups").to_a
    client.stock.iterate_moves.to_a

    assert_equal(%w[50 50 100], @http.requests.map { |r| query(r)["limit"].first })
  end

  def test_get_product_encodes_the_id_and_expand
    @http.json(200, { data: PRODUCT })

    product = client.menu.get_product("a/b c", expand: "translations")

    assert_equal "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations", @http.last.url
    assert_equal "Plov", product.name
  end

  def test_empty_id_is_rejected
    assert_raises(ArgumentError) { client.orders.get("") }
    assert_raises(ArgumentError) { client.orders.get(" ") }
    assert_raises(ArgumentError) { client.orders.get(nil) }
  end

  def test_categories_and_stop_list
    @http.json(200, { data: { items: [{ name: "Salads", position: 1, products: 9, available: 8 }], total: 1 } })
    @http.json(200, { data: { items: [{ id: "p9", name: "Dolma", category: "Main", price: 9.5 }], total: 1 } })

    assert_equal 8, client.menu.list_categories.first.available
    assert_equal "Dolma", client.menu.get_stop_list.first.name
    assert_equal "/v1/menu/stop-list", path(@http.last)
  end

  def test_reservation_parses_nested_fields_and_times
    @http.json(200, { data: RESERVATION })

    reservation = client.reservations.get("res1")

    assert_equal Time.utc(2026, 11, 20, 15, 30), reservation.starts_at
    assert_predicate reservation.starts_at, :utc?
    assert_equal Time.utc(2026, 11, 20, 17, 30, 0, Rational(123_456_789, 1000)), reservation.ends_at
    assert_equal 123_456_789, reservation.ends_at.nsec
    assert_equal Time.utc(2026, 11, 11, 10, 0, 0, 500_000), reservation.created_at
    assert_nil reservation.decided_at
    assert_equal "T5", reservation.table.label
    assert_equal "+994501234567", reservation.guest.phone
    assert_nil reservation.guest.email
    assert_equal 2, reservation.pre_order.first.qty
    assert_in_delta 0.0, reservation.deposit_paid
  end

  def test_availability
    @http.json(200, {
                 data: {
                   startsAt: "2026-11-20T15:30:00Z", endsAt: "2026-11-20T17:30:00Z", durationMinutes: 120,
                   openTime: "10:00", closeTime: "23:00",
                   tables: [{ id: "t5", label: "T5", hallId: "h1", zone: "Terrace", seats: 4, free: true }]
                 }
               })

    result = client.reservations.availability(Date.new(2026, 11, 20), "19:30", guests: 4)

    assert_equal "/v1/reservations/availability", path(@http.last)
    assert_equal({ "date" => ["2026-11-20"], "time" => ["19:30"], "guests" => ["4"] }, query(@http.last))
    assert_equal 120, result.duration_minutes
    assert result.tables.first.free
  end

  def test_create_reservation_posts_json_and_reports_created
    @http.json(201, { data: RESERVATION })

    result = client.reservations.create(
      date: Date.new(2026, 11, 20),
      time: "19:30",
      guests: 4,
      guest_name: "Aysel Məmmədova",
      phone: "+994501234567",
      child_chair: true,
      pre_order: [Noosh24::PreOrderLine.new(item_id: "p1", qty: 2), { item_id: "p2", qty: 1, note: "no onion" }],
      external_ref: "acme-991"
    )

    request = @http.last

    assert_equal "POST", request.http_method
    assert_equal "https://open-api.noosh24.com/v1/reservations", request.url
    assert_equal "application/json", request.headers["Content-Type"]
    assert_equal({
                   "date" => "2026-11-20",
                   "time" => "19:30",
                   "guests" => 4,
                   "guestName" => "Aysel Məmmədova",
                   "phone" => "+994501234567",
                   "childChair" => true,
                   "externalRef" => "acme-991",
                   "preOrder" => [{ "itemId" => "p1", "qty" => 2 },
                                  { "itemId" => "p2", "qty" => 1, "note" => "no onion" }]
                 }, body(request))
    assert_includes request.body, "Məmmədova"
    assert_predicate result, :created?
    assert_equal "K7Q2", result.reservation.code
  end

  def test_create_accepts_a_new_reservation
    @http.json(201, { data: RESERVATION })

    booking = Noosh24::NewReservation.new(**BOOKING, email: "a@example.com", table_id: "t5")
    client.reservations.create(booking)

    assert_equal({ "date" => "2026-11-20", "time" => "19:30", "guests" => 4, "guestName" => "Aysel Məmmədova",
                   "phone" => "+994501234567", "email" => "a@example.com", "tableId" => "t5" }, body(@http.last))
  end

  def test_create_with_known_external_ref_returns_the_existing_booking
    @http.json(200, { data: RESERVATION })

    result = client.reservations.create(**BOOKING, external_ref: "acme-991")

    refute_predicate result, :created?
    assert_equal "res1", result.reservation.id
  end

  def test_create_with_external_ref_is_retried
    @http.json(503, { error: "temporarily_unavailable" }, { "Retry-After" => "0" })
    @http.json(201, { data: RESERVATION })

    result = client.reservations.create(**BOOKING, external_ref: "acme-991")

    assert_predicate result, :created?
    assert_equal 2, @http.requests.size
    assert_equal @http.requests[0].body, @http.requests[1].body
    assert_equal [0.0], @sleeps
  end

  def test_create_without_external_ref_is_never_retried
    @http.json(503, { error: "temporarily_unavailable" }, { "Retry-After" => "0" })

    assert_raises(Noosh24::ServerError) { client.reservations.create(**BOOKING) }
    assert_equal 1, @http.requests.size
  end

  def test_create_with_blank_external_ref_is_never_retried
    @http.fail_with(Errno::ECONNRESET.new)

    assert_raises(Noosh24::APIConnectionError) { client.reservations.create(**BOOKING, external_ref: "  ") }
    assert_equal 1, @http.requests.size
  end

  def test_table_taken
    @http.json(409, { error: "table_taken", message: "Bu masa seçilən vaxt üçün artıq tutulub" })

    error = assert_raises(Noosh24::TableTakenError) do
      client.reservations.create(**BOOKING, table_id: "t5", external_ref: "x")
    end
    assert_match(/artıq tutulub/, error.message)
  end

  def test_cancel
    @http.json(200, { data: RESERVATION.merge("status" => "cancelled") })

    reservation = client.reservations.cancel("res1")

    assert_equal "POST", @http.last.http_method
    assert_equal "https://open-api.noosh24.com/v1/reservations/res1/cancel", @http.last.url
    assert_nil @http.last.body
    assert_equal "cancelled", reservation.status
  end

  def test_orders_bills_payments_and_z_report
    @http.json(200, {
                 data: {
                   id: "o1", number: "A-12", dailyNumber: 12, kind: "delivery", status: "ready", subtotal: 30,
                   items: [{ id: "i1", productId: "p1", name: "Plov", qty: 2, price: 15, comp: false }],
                   delivery: {
                     status: "accepted", platform: { id: "wolt", name: "Wolt", ref: "W-1" }, fee: 2,
                     acceptedAt: "2026-11-11T09:00:00Z"
                   }
                 }
               })
    @http.json(200, { data: { id: "b1", status: "paid", orderIds: %w[o1 o2], total: 45.5, closedAt: nil } })
    @http.json(200, {
                 data: {
                   id: "pay1", method: "card", amount: 20,
                   card: { maskedPan: "4169********1234", scheme: "visa", bank: "Kapital" }, platform: nil
                 }
               })
    @http.json(200, { data: { date: "2026-11-10", cash: 120.5 } })

    order = client.orders.get("o1")
    bill = client.orders.get_bill("b1")
    payment = client.payments.get("pay1")
    z = client.payments.z_report("2026-11-10")

    assert_equal "Wolt", order.delivery.platform.name
    assert_in_delta 2.0, order.delivery.fee
    assert_equal Time.utc(2026, 11, 11, 9), order.delivery.accepted_at
    assert_in_delta 15.0, order.items.first.price
    assert_equal %w[o1 o2], bill.order_ids
    assert_nil bill.closed_at
    assert_equal "4169********1234", payment.card.masked_pan
    assert_nil payment.platform
    assert_in_delta 120.5, z["cash"]
    assert_equal({ "date" => ["2026-11-10"] }, query(@http.last))
    assert_equal(["/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"],
                 @http.requests.map { |r| path(r) })
  end

  def test_z_report_without_date
    @http.json(200, { data: { cash: 1 } })

    client.payments.z_report

    assert_equal "https://open-api.noosh24.com/v1/reports/z", @http.last.url
  end

  def test_tables_loyalty_stock_and_reviews
    @http.json(200, { data: { items: [{ id: "t1", label: "T1", status: "occupied", billTotal: 42.1 }], total: 1 } })
    @http.json(200, { data: { stampsNeeded: 8, earnBy: "visit", rewardProductIds: ["p1"] } })
    @http.json(200, page([{ id: "card1", stamps: 5, lastVisitAt: nil }], 1, 100))
    @http.json(200, page([{ id: "ing1", name: "Rice", stock: 12, byStore: { s1: 10, s2: 2.5 } }], 1))
    @http.json(200, { data: { items: [{ id: "s1", name: "Main", isDefault: true, stations: ["hot"] }], total: 1 } })
    @http.json(200, page([{ id: "rv1", overall: 4.5, ratings: { food: 5, service: 4 }, reply: nil }], 1))

    assert_in_delta 42.1, client.tables.list.first.bill_total
    assert_equal 8, client.loyalty.get_program.stamps_needed
    refute_predicate client.loyalty.list_cards, :has_more?
    assert_equal({ "s1" => 10.0, "s2" => 2.5 }, client.stock.list_ingredients.items.first.by_store)
    assert client.stock.list_stores.first.is_default
    review = client.reviews.list.items.first

    assert_in_delta 5.0, review.ratings.food
    assert_nil review.ratings.price
    assert_equal(["/v1/tables", "/v1/loyalty/program", "/v1/loyalty/cards", "/v1/stock/ingredients",
                  "/v1/stock/stores", "/v1/reviews"], @http.requests.map { |r| path(r) })
  end

  def test_other_iterators_and_lists_use_their_paths
    6.times { @http.json(200, page([], 0)) }

    client.reservations.iterate.to_a
    client.orders.iterate.to_a
    client.loyalty.iterate_cards.to_a
    client.stock.iterate_ingredients.to_a
    client.stock.list_moves
    client.reviews.iterate.to_a

    assert_equal(["/v1/reservations", "/v1/orders", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/stock/moves",
                  "/v1/reviews"], @http.requests.map { |r| path(r) })
  end

  def test_models_tolerate_missing_and_unknown_fields
    @http.json(201, { data: { id: "res9", code: "ZZ11", status: "pending", brandNew: 1 } })

    result = client.reservations.create(**BOOKING)

    assert_equal "ZZ11", result.reservation.code
    assert_nil result.reservation.guest
    assert_nil result.reservation.starts_at
    assert_equal [], result.reservation.pre_order
    assert_equal 1, result.reservation.raw["brandNew"]
  end
end
