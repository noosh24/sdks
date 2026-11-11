package noosh24

import (
	"bytes"
	"encoding/json"
	"errors"
	"maps"
	"net/url"
	"reflect"
	"slices"
	"strings"
	"testing"
	"time"
)

func product() map[string]any {
	return map[string]any{
		"id":           "0b6f3c1e",
		"name":         "Plov",
		"category":     "Main",
		"description":  "Saffron rice with lamb",
		"price":        14,
		"available":    true,
		"popular":      true,
		"position":     3,
		"prepMinutes":  20,
		"station":      "",
		"vatRate":      nil,
		"vegetarian":   false,
		"spicy":        false,
		"allergens":    []string{"gluten"},
		"discountable": true,
		"hasModifiers": true,
		"image":        "https://api.noosh24.com/m/5c1d.jpg",
		"video":        nil,
		"modifierGroups": []any{map[string]any{
			"id": "g1", "name": "Size", "required": true, "position": 0,
			"modifiers": []any{map[string]any{"id": "m1", "name": "Large", "priceDelta": 2.5, "position": 0}},
		}},
		"translations": map[string]any{"en": map[string]any{"name": "Pilaf", "description": "Rice"}, "ru": map[string]any{"name": "Плов"}},
	}
}

func reservation() map[string]any {
	return map[string]any{
		"id":             "res1",
		"code":           "K7Q2",
		"status":         "pending",
		"source":         "open_api",
		"startsAt":       "2026-11-20T15:30:00Z",
		"endsAt":         "2026-11-20T17:30:00.123456789Z",
		"guests":         4,
		"zone":           "Terrace",
		"table":          map[string]any{"id": "t5", "label": "T5"},
		"guest":          map[string]any{"name": "Aysel", "phone": "+994501234567", "email": nil},
		"specialRequest": nil,
		"allergyNote":    nil,
		"birthday":       false,
		"childChair":     true,
		"depositPaid":    0,
		"preOrder":       []any{map[string]any{"productId": "p1", "name": "Plov", "price": 14.5, "qty": 2, "note": nil}},
		"externalRef":    "acme-991",
		"decidedAt":      nil,
		"createdAt":      "2026-11-11T10:00:00.5Z",
		"updatedAt":      "2026-11-11T10:00:00Z",
	}
}

func booking() *NewReservation {
	return &NewReservation{Date: "2026-11-20", Time: "19:30", Guests: 4, GuestName: "Aysel Məmmədova", Phone: "+994501234567"}
}

func queryEqual(t *testing.T, got url.Values, want map[string][]string) {
	t.Helper()
	if !maps.EqualFunc(map[string][]string(got), want, slices.Equal) {
		t.Fatalf("query = %v, want %v", got, want)
	}
}

func TestListProductsSendsListParametersAndParsesThePage(t *testing.T) {
	m := newMock(t)
	m.json(200, page([]map[string]any{product()}, 87, 50, 50))

	result := must(m.client().Menu.ListProducts(ctx(), &ListParams{
		Limit:  50,
		Offset: 50,
		Sort:   []string{"category asc", "price desc"},
		Where:  NewWhere().Eq("category", "Chef's").Gte("price", 5).Eq("available", true),
		Expand: []Expand{ExpandModifierGroups, ExpandTranslations},
	}))

	r := m.last()
	equal(t, r.URL.Path, "/v1/menu/products")
	queryEqual(t, r.query(), map[string][]string{
		"limit":  {"50"},
		"offset": {"50"},
		"sort":   {"category asc", "price desc"},
		"where":  {"category = 'Chef''s' AND price >= 5 AND available = true"},
		"expand": {"modifierGroups", "translations"},
	})
	if !strings.Contains(r.URL.RawQuery, "where=category%20%3D%20%27Chef%27%27s%27") || strings.Contains(r.URL.RawQuery, "+") {
		t.Fatalf("raw query = %s", r.URL.RawQuery)
	}
	equal(t, result.Total, 87)
	equal(t, result.Limit, 50)
	equal(t, result.Offset, 50)
	equal(t, result.HasMore(), true)
	equal(t, result.NextOffset(), 51)
	equal(t, len(result.Items), 1)
	p := result.Items[0]
	equal(t, p.Price, 14.0)
	if p.VatRate != nil {
		t.Fatalf("vatRate = %v", *p.VatRate)
	}
	equal(t, *p.Image, "https://api.noosh24.com/m/5c1d.jpg")
	if p.Video != nil {
		t.Fatal("video should be nil")
	}
	equal(t, p.PrepMinutes, 20)
	if !slices.Equal(p.Allergens, []string{"gluten"}) {
		t.Fatalf("allergens = %v", p.Allergens)
	}
	equal(t, p.ModifierGroups[0].Modifiers[0].PriceDelta, 2.5)
	equal(t, p.Translations["en"].Name, "Pilaf")
	equal(t, p.Translations["ru"].Description, "")
	var raw, want any
	_ = json.Unmarshal(p.RawJSON, &raw)
	wantBytes, _ := json.Marshal(product())
	_ = json.Unmarshal(wantBytes, &want)
	if !reflect.DeepEqual(raw, want) {
		t.Fatalf("raw = %s", p.RawJSON)
	}
}

func TestListAcceptsPlainWhereAndSingleSort(t *testing.T) {
	m := newMock(t)
	m.json(200, page(nil, 0, 20, 0))

	must(m.client().Orders.List(ctx(), &ListParams{Where: RawWhere("status = 'served'"), Sort: []string{"createdAt desc"}}))

	queryEqual(t, m.last().query(), map[string][]string{"sort": {"createdAt desc"}, "where": {"status = 'served'"}})
}

func TestListWithoutParams(t *testing.T) {
	m := newMock(t)
	m.json(200, page(nil, 0, 20, 0))

	result := must(m.client().Reviews.List(ctx(), nil))

	equal(t, m.last().URL.RawQuery, "")
	equal(t, result.HasMore(), false)
}

func TestExpandIsRejectedOutsideProducts(t *testing.T) {
	m := newMock(t)

	_, err := m.client().Reviews.List(ctx(), &ListParams{Expand: []Expand{ExpandTranslations}})

	if !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 0)
}

func TestIteratorWalksEveryPage(t *testing.T) {
	m := newMock(t)
	m.json(200, page([]map[string]any{{"id": "c1"}, {"id": "c2"}}, 5, 2, 0))
	m.json(200, page([]map[string]any{{"id": "c3"}, {"id": "c4"}}, 5, 2, 2))
	m.json(200, page([]map[string]any{{"id": "c5"}}, 5, 2, 4))

	var ids []string
	for customer, err := range m.client().Customers.Iterate(ctx(), &ListParams{Limit: 2, Where: RawWhere("createdAt >= '2026-11-01'")}) {
		if err != nil {
			t.Fatal(err)
		}
		ids = append(ids, customer.ID)
	}

	if !slices.Equal(ids, []string{"c1", "c2", "c3", "c4", "c5"}) {
		t.Fatalf("ids = %v", ids)
	}
	var offsets []string
	for _, r := range m.all() {
		offsets = append(offsets, r.query().Get("offset"))
	}
	if !slices.Equal(offsets, []string{"0", "2", "4"}) {
		t.Fatalf("offsets = %v", offsets)
	}
	equal(t, m.all()[2].query().Get("where"), "createdAt >= '2026-11-01'")
	equal(t, m.all()[2].query().Get("limit"), "2")
}

func TestIteratorStartsAtTheGivenOffset(t *testing.T) {
	m := newMock(t)
	m.json(200, page([]map[string]any{{"id": "c9"}}, 10, 100, 9))

	var n int
	for _, err := range m.client().Customers.Iterate(ctx(), &ListParams{Offset: 9}) {
		if err != nil {
			t.Fatal(err)
		}
		n++
	}

	equal(t, n, 1)
	equal(t, m.last().query().Get("offset"), "9")
	equal(t, m.last().query().Get("limit"), "100")
}

func TestIteratorIsLazy(t *testing.T) {
	m := newMock(t)
	seq := m.client().Payments.Iterate(ctx(), nil)
	equal(t, len(m.all()), 0)
	m.json(200, page(nil, 10, 100, 0))

	var n int
	for _, err := range seq {
		if err != nil {
			t.Fatal(err)
		}
		n++
	}

	equal(t, n, 0)
	equal(t, len(m.all()), 1)
}

func TestIteratorStopsOnBreakAndYieldsErrors(t *testing.T) {
	m := newMock(t)
	m.json(200, page([]map[string]any{{"id": "a"}, {"id": "b"}}, 10, 2, 0))
	for range m.client().Orders.Iterate(ctx(), nil) {
		break
	}
	equal(t, len(m.all()), 1)

	m.json(404, map[string]any{"error": "not_found", "message": "gone"})
	var errs []error
	for order, err := range m.client(WithMaxRetries(0)).Orders.Iterate(ctx(), nil) {
		equal(t, order.ID, "")
		errs = append(errs, err)
	}
	if len(errs) != 1 || !IsNotFound(errs[0]) {
		t.Fatalf("errs = %v", errs)
	}
}

func TestIteratorUsesTheLargestPageEachEndpointAllows(t *testing.T) {
	m := newMock(t)
	for range 3 {
		m.json(200, page(nil, 0, 20, 0))
	}
	c := m.client()
	for _, err := range c.Orders.IterateBills(ctx(), nil) {
		if err != nil {
			t.Fatal(err)
		}
	}
	for _, err := range c.Menu.IterateProducts(ctx(), &ListParams{Expand: []Expand{ExpandModifierGroups}}) {
		if err != nil {
			t.Fatal(err)
		}
	}
	for _, err := range c.Stock.IterateMoves(ctx(), nil) {
		if err != nil {
			t.Fatal(err)
		}
	}

	var limits []string
	for _, r := range m.all() {
		limits = append(limits, r.query().Get("limit"))
	}
	if !slices.Equal(limits, []string{"50", "50", "100"}) {
		t.Fatalf("limits = %v", limits)
	}
}

func TestGetProductEncodesTheIDAndExpand(t *testing.T) {
	m := newMock(t)
	m.json(200, data(product()))

	p := must(m.client().Menu.GetProduct(ctx(), "a/b c", ExpandTranslations))

	equal(t, m.last().URL.String(), "https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations")
	equal(t, p.Name, "Plov")
}

func TestEmptyIDIsRejected(t *testing.T) {
	m := newMock(t)
	c := m.client()

	_, err := c.Orders.Get(ctx(), "")
	if !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
	_, err = c.Reservations.Cancel(ctx(), " ")
	if !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 0)
}

func TestCategoriesAndStopList(t *testing.T) {
	m := newMock(t)
	m.json(200, items(map[string]any{"name": "Salads", "position": 1, "products": 9, "available": 8}))
	m.json(200, items(map[string]any{"id": "p9", "name": "Dolma", "category": "Main", "price": 9.5}))
	c := m.client()

	categories := must(c.Menu.ListCategories(ctx()))
	stop := must(c.Menu.GetStopList(ctx()))

	equal(t, categories[0].Available, 8)
	equal(t, stop[0].Name, "Dolma")
	equal(t, stop[0].Price, 9.5)
	equal(t, m.all()[0].URL.Path, "/v1/menu/categories")
	equal(t, m.last().URL.Path, "/v1/menu/stop-list")
}

func TestReservationParsesNestedFieldsAndTimes(t *testing.T) {
	m := newMock(t)
	m.json(200, data(reservation()))

	r := must(m.client().Reservations.Get(ctx(), "res1"))

	equal(t, m.last().URL.Path, "/v1/reservations/res1")
	if !r.StartsAt.Equal(time.Date(2026, 11, 20, 15, 30, 0, 0, time.UTC)) {
		t.Fatalf("startsAt = %v", r.StartsAt)
	}
	if !r.EndsAt.Equal(time.Date(2026, 11, 20, 17, 30, 0, 123456789, time.UTC)) {
		t.Fatalf("endsAt = %v", r.EndsAt)
	}
	if !r.CreatedAt.Equal(time.Date(2026, 11, 11, 10, 0, 0, 500000000, time.UTC)) {
		t.Fatalf("createdAt = %v", r.CreatedAt)
	}
	if r.DecidedAt != nil || r.SpecialRequest != nil {
		t.Fatal("null fields should be nil")
	}
	equal(t, r.Status, ReservationStatusPending)
	equal(t, r.Source, ReservationSourceOpenApi)
	equal(t, r.Table.Label, "T5")
	equal(t, r.Guest.Phone, "+994501234567")
	if r.Guest.Email != nil {
		t.Fatal("email should be nil")
	}
	equal(t, r.PreOrder[0].Qty, 2)
	equal(t, *r.PreOrder[0].ProductID, "p1")
	equal(t, r.DepositPaid, 0.0)
	equal(t, *r.ExternalRef, "acme-991")
	equal(t, r.ChildChair, true)
}

func TestAvailability(t *testing.T) {
	m := newMock(t)
	m.json(200, data(map[string]any{
		"startsAt":        "2026-11-20T15:30:00Z",
		"endsAt":          "2026-11-20T17:30:00Z",
		"durationMinutes": 120,
		"openTime":        "10:00",
		"closeTime":       "23:00",
		"tables":          []any{map[string]any{"id": "t5", "label": "T5", "hallId": "h1", "zone": "Terrace", "seats": 4, "free": true}},
	}))

	result := must(m.client().Reservations.Availability(ctx(), "2026-11-20", "19:30", 4))

	equal(t, m.last().URL.Path, "/v1/reservations/availability")
	queryEqual(t, m.last().query(), map[string][]string{"date": {"2026-11-20"}, "time": {"19:30"}, "guests": {"4"}})
	equal(t, result.DurationMinutes, 120)
	equal(t, result.Tables[0].Free, true)
	equal(t, result.Tables[0].HallID, "h1")

	m.json(200, data(map[string]any{}))
	must(m.client().Reservations.Availability(ctx(), "2026-11-20", "19:30", 0))
	queryEqual(t, m.last().query(), map[string][]string{"date": {"2026-11-20"}, "time": {"19:30"}})
}

func TestCreateReservationPostsJSONAndReportsCreated(t *testing.T) {
	m := newMock(t)
	m.json(201, data(reservation()))
	b := booking()
	b.ChildChair = Bool(true)
	b.PreOrder = []PreOrderLine{{ItemID: "p1", Qty: 2}, {ItemID: "p2", Qty: 1, Note: "no onion"}}
	b.ExternalRef = "acme-991"

	result := must(m.client().Reservations.Create(ctx(), b))

	r := m.last()
	equal(t, r.Method, "POST")
	equal(t, r.URL.String(), "https://open-api.noosh24.com/v1/reservations")
	equal(t, r.Header.Get("Content-Type"), "application/json")
	got := r.json(t)
	want := map[string]any{
		"date":        "2026-11-20",
		"time":        "19:30",
		"guests":      float64(4),
		"guestName":   "Aysel Məmmədova",
		"phone":       "+994501234567",
		"childChair":  true,
		"externalRef": "acme-991",
		"preOrder": []any{
			map[string]any{"itemId": "p1", "qty": float64(2)},
			map[string]any{"itemId": "p2", "qty": float64(1), "note": "no onion"},
		},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("body = %s", r.Body)
	}
	if !bytes.Contains(r.Body, []byte("Məmmədova")) {
		t.Fatalf("body is not raw UTF-8: %s", r.Body)
	}
	equal(t, result.Created, true)
	equal(t, result.Reservation.Code, "K7Q2")
}

func TestCreateOmitsUnsetOptionals(t *testing.T) {
	m := newMock(t)
	m.json(201, data(map[string]any{"id": "r"}))
	b := booking()
	b.Birthday = Bool(false)

	must(m.client().Reservations.Create(ctx(), b))

	got := m.last().json(t)
	keys := slices.Sorted(maps.Keys(got))
	if !slices.Equal(keys, []string{"birthday", "date", "guestName", "guests", "phone", "time"}) {
		t.Fatalf("keys = %v", keys)
	}
	equal(t, got["birthday"], any(false))
}

func TestCreateWithKnownExternalRefReturnsTheExistingBooking(t *testing.T) {
	m := newMock(t)
	m.json(200, data(reservation()))
	b := booking()
	b.ExternalRef = "acme-991"

	result := must(m.client().Reservations.Create(ctx(), b))

	equal(t, result.Created, false)
	equal(t, result.Reservation.ID, "res1")
}

func TestCreateWithExternalRefIsRetried(t *testing.T) {
	m := newMock(t)
	m.json(503, map[string]any{"error": "temporarily_unavailable"}, map[string]string{"Retry-After": "0"})
	m.json(201, data(reservation()))
	b := booking()
	b.ExternalRef = "acme-991"

	result := must(m.client().Reservations.Create(ctx(), b))

	equal(t, result.Created, true)
	reqs := m.all()
	equal(t, len(reqs), 2)
	if !bytes.Equal(reqs[0].Body, reqs[1].Body) || len(reqs[0].Body) == 0 {
		t.Fatalf("bodies differ: %s / %s", reqs[0].Body, reqs[1].Body)
	}
	if !slices.Equal(m.slept(), []time.Duration{0}) {
		t.Fatalf("slept %v", m.slept())
	}
}

func TestCreateWithoutExternalRefIsNeverRetried(t *testing.T) {
	m := newMock(t)
	m.json(503, map[string]any{"error": "temporarily_unavailable"}, map[string]string{"Retry-After": "0"})

	_, err := m.client().Reservations.Create(ctx(), booking())

	if !IsServerError(err) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 1)

	m.fail(errors.New("connection reset"))
	b := booking()
	b.ExternalRef = "  "
	_, err = m.client().Reservations.Create(ctx(), b)
	if !errors.Is(err, ErrConnection) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 2)
}

func TestCreateNeedsAReservation(t *testing.T) {
	m := newMock(t)
	if _, err := m.client().Reservations.Create(ctx(), nil); !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
}

func TestTableTaken(t *testing.T) {
	m := newMock(t)
	m.json(409, map[string]any{"error": "table_taken", "message": "Bu masa seçilən vaxt üçün artıq tutulub"})
	b := booking()
	b.TableID = "t5"
	b.ExternalRef = "x"

	_, err := m.client().Reservations.Create(ctx(), b)

	if !IsTableTaken(err) || !IsConflict(err) || !strings.Contains(err.Error(), "artıq tutulub") {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 1)
}

func TestCancel(t *testing.T) {
	m := newMock(t)
	cancelled := reservation()
	cancelled["status"] = "cancelled"
	m.json(200, data(cancelled))

	r := must(m.client().Reservations.Cancel(ctx(), "res1"))

	equal(t, m.last().Method, "POST")
	equal(t, m.last().URL.String(), "https://open-api.noosh24.com/v1/reservations/res1/cancel")
	equal(t, len(m.last().Body), 0)
	equal(t, m.last().Header.Get("Content-Type"), "")
	equal(t, r.Status, ReservationStatusCancelled)
}

func TestReservationsListAndIterate(t *testing.T) {
	m := newMock(t)
	m.json(200, page([]map[string]any{reservation()}, 1, 20, 0))
	m.json(200, page([]map[string]any{reservation()}, 1, 100, 0))
	c := m.client()

	result := must(c.Reservations.List(ctx(), &ListParams{Where: NewWhere().Eq("status", "pending")}))
	equal(t, result.Items[0].Code, "K7Q2")
	for r, err := range c.Reservations.Iterate(ctx(), nil) {
		if err != nil {
			t.Fatal(err)
		}
		equal(t, r.ID, "res1")
	}
	equal(t, m.all()[0].URL.Path, "/v1/reservations")
	equal(t, m.last().query().Get("limit"), "100")
}

func TestOrdersBillsPaymentsAndZReport(t *testing.T) {
	m := newMock(t)
	m.json(200, data(map[string]any{
		"id": "o1", "number": "A-12", "dailyNumber": 12, "kind": "delivery", "status": "ready", "subtotal": 30,
		"items": []any{map[string]any{"id": "i1", "productId": "p1", "name": "Plov", "qty": 2, "price": 15, "comp": false}},
		"delivery": map[string]any{
			"status":     "accepted",
			"platform":   map[string]any{"id": "wolt", "name": "Wolt", "ref": "W-1"},
			"fee":        2,
			"acceptedAt": "2026-11-11T09:00:00Z",
		},
	}))
	m.json(200, data(map[string]any{"id": "b1", "status": "paid", "orderIds": []string{"o1", "o2"}, "total": 45.5, "closedAt": nil}))
	m.json(200, data(map[string]any{
		"id": "pay1", "method": "card", "amount": 20,
		"card":     map[string]any{"maskedPan": "4169********1234", "scheme": "visa", "bank": "Kapital"},
		"platform": nil,
	}))
	m.json(200, data(map[string]any{"date": "2026-11-10", "cash": 120.5}))
	c := m.client()

	order := must(c.Orders.Get(ctx(), "o1"))
	bill := must(c.Orders.GetBill(ctx(), "b1"))
	payment := must(c.Payments.Get(ctx(), "pay1"))
	z := must(c.Payments.ZReport(ctx(), "2026-11-10"))

	equal(t, order.Kind, OrderKindDelivery)
	equal(t, *order.DailyNumber, 12)
	equal(t, *order.Delivery.Platform.Name, "Wolt")
	equal(t, *order.Delivery.Fee, 2.0)
	if !order.Delivery.AcceptedAt.Equal(time.Date(2026, 11, 11, 9, 0, 0, 0, time.UTC)) {
		t.Fatalf("acceptedAt = %v", order.Delivery.AcceptedAt)
	}
	equal(t, order.Items[0].Price, 15.0)
	if !slices.Equal(bill.OrderIDs, []string{"o1", "o2"}) {
		t.Fatalf("orderIds = %v", bill.OrderIDs)
	}
	if bill.ClosedAt != nil {
		t.Fatal("closedAt should be nil")
	}
	equal(t, bill.Status, BillStatusPaid)
	equal(t, payment.Method, PaymentMethodCard)
	equal(t, payment.Card.MaskedPan, "4169********1234")
	if payment.Platform != nil {
		t.Fatal("platform should be nil")
	}
	equal(t, z["cash"], any(120.5))
	queryEqual(t, m.last().query(), map[string][]string{"date": {"2026-11-10"}})
	var paths []string
	for _, r := range m.all() {
		paths = append(paths, r.URL.Path)
	}
	if !slices.Equal(paths, []string{"/v1/orders/o1", "/v1/bills/b1", "/v1/payments/pay1", "/v1/reports/z"}) {
		t.Fatalf("paths = %v", paths)
	}

	m.json(200, data(map[string]any{"cash": 1}))
	must(c.Payments.ZReport(ctx(), ""))
	equal(t, m.last().URL.RawQuery, "")
}

func TestOrderBillAndPaymentLists(t *testing.T) {
	m := newMock(t)
	for range 6 {
		m.json(200, page([]map[string]any{{"id": "x"}}, 1, 20, 0))
	}
	c := m.client()

	must(c.Orders.List(ctx(), nil))
	must(c.Orders.ListBills(ctx(), nil))
	must(c.Payments.List(ctx(), nil))
	must(c.Customers.List(ctx(), nil))
	for _, err := range c.Stock.IterateIngredients(ctx(), nil) {
		if err != nil {
			t.Fatal(err)
		}
	}
	for _, err := range c.Loyalty.IterateCards(ctx(), nil) {
		if err != nil {
			t.Fatal(err)
		}
	}

	var paths []string
	for _, r := range m.all() {
		paths = append(paths, r.URL.Path)
	}
	if !slices.Equal(paths, []string{"/v1/orders", "/v1/bills", "/v1/payments", "/v1/customers", "/v1/stock/ingredients", "/v1/loyalty/cards"}) {
		t.Fatalf("paths = %v", paths)
	}
}

func TestTablesLoyaltyStockAndReviews(t *testing.T) {
	m := newMock(t)
	m.json(200, items(map[string]any{"id": "t1", "label": "T1", "status": "occupied", "billTotal": 42.1}))
	m.json(200, data(map[string]any{"stampsNeeded": 8, "earnBy": "visit", "rewardProductIds": []string{"p1"}}))
	m.json(200, page([]map[string]any{{"id": "card1", "stamps": 5, "lastVisitAt": nil}}, 1, 100, 0))
	m.json(200, page([]map[string]any{{"id": "ing1", "name": "Rice", "stock": 12, "byStore": map[string]any{"s1": 10, "s2": 2.5}}}, 1, 20, 0))
	m.json(200, items(map[string]any{"id": "s1", "name": "Main", "isDefault": true, "stations": []string{"hot"}}))
	m.json(200, page([]map[string]any{{"id": "mv1", "qty": -0.25, "reason": "sale"}}, 1, 20, 0))
	m.json(200, page([]map[string]any{{"id": "rv1", "overall": 4.5, "ratings": map[string]any{"food": 5, "service": 4}, "reply": nil, "visitedOn": "2026-11-02T00:00:00Z"}}, 1, 20, 0))
	c := m.client()

	tables := must(c.Tables.List(ctx()))
	program := must(c.Loyalty.GetProgram(ctx()))
	cards := must(c.Loyalty.ListCards(ctx(), nil))
	ingredients := must(c.Stock.ListIngredients(ctx(), nil))
	stores := must(c.Stock.ListStores(ctx()))
	moves := must(c.Stock.ListMoves(ctx(), nil))
	reviews := must(c.Reviews.List(ctx(), nil))

	equal(t, *tables[0].BillTotal, 42.1)
	equal(t, tables[0].Status, TableStatusOccupied)
	equal(t, program.StampsNeeded, 8)
	equal(t, program.EarnBy, LoyaltyProgramEarnByVisit)
	if !slices.Equal(program.RewardProductIDs, []string{"p1"}) {
		t.Fatalf("rewardProductIds = %v", program.RewardProductIDs)
	}
	equal(t, cards.HasMore(), false)
	if cards.Items[0].LastVisitAt != nil {
		t.Fatal("lastVisitAt should be nil")
	}
	if !maps.Equal(ingredients.Items[0].ByStore, map[string]float64{"s1": 10, "s2": 2.5}) {
		t.Fatalf("byStore = %v", ingredients.Items[0].ByStore)
	}
	equal(t, stores[0].IsDefault, true)
	equal(t, moves.Items[0].Qty, -0.25)
	review := reviews.Items[0]
	equal(t, review.Ratings.Food, 5.0)
	equal(t, review.Ratings.Price, 0.0)
	equal(t, review.VisitedOn.Day(), 2)
	if review.Reply != nil {
		t.Fatal("reply should be nil")
	}
	var paths []string
	for _, r := range m.all() {
		paths = append(paths, r.URL.Path)
	}
	if !slices.Equal(paths, []string{"/v1/tables", "/v1/loyalty/program", "/v1/loyalty/cards", "/v1/stock/ingredients", "/v1/stock/stores", "/v1/stock/moves", "/v1/reviews"}) {
		t.Fatalf("paths = %v", paths)
	}
	equal(t, m.all()[1].URL.RawQuery, "")
}

func TestModelsTolerateMissingAndUnknownFields(t *testing.T) {
	m := newMock(t)
	m.json(201, data(map[string]any{"id": "res9", "code": "ZZ11", "status": "pending", "brandNew": 1}))

	result := must(m.client().Reservations.Create(ctx(), booking()))

	equal(t, result.Created, true)
	equal(t, result.Reservation.Code, "ZZ11")
	if result.Reservation.Guest != nil || result.Reservation.PreOrder != nil {
		t.Fatal("missing fields should be nil")
	}
	if !result.Reservation.StartsAt.IsZero() {
		t.Fatal("missing time should be zero")
	}
	var raw map[string]any
	_ = json.Unmarshal(result.Reservation.RawJSON, &raw)
	equal(t, raw["brandNew"], any(float64(1)))
}

func TestModelsTolerateWrongTypes(t *testing.T) {
	var p Product
	err := json.Unmarshal([]byte(`{"id":7,"price":"cheap","position":2.9,"available":1,"allergens":["a",null,3,{}],"modifierGroups":[1,{"id":"g"}],"image":{"x":1}}`), &p)
	equal(t, err, nil)
	equal(t, p.ID, "7")
	equal(t, p.Price, 0.0)
	equal(t, p.Position, 2)
	equal(t, p.Available, true)
	if !slices.Equal(p.Allergens, []string{"a", "3"}) {
		t.Fatalf("allergens = %v", p.Allergens)
	}
	equal(t, len(p.ModifierGroups), 1)
	if p.Image != nil {
		t.Fatal("image should be nil")
	}
	var r Reservation
	equal(t, json.Unmarshal([]byte(`null`), &r), nil)
	equal(t, json.Unmarshal([]byte(`{"startsAt":"2026-11-20 15:30:00","endsAt":"2026-11-20","createdAt":"soon"}`), &r), nil)
	equal(t, r.StartsAt.Hour(), 15)
	equal(t, r.EndsAt.Day(), 20)
	equal(t, r.CreatedAt.IsZero(), true)
}

func TestModelsMarshalWithAPINames(t *testing.T) {
	var p Product
	_ = json.Unmarshal([]byte(`{"id":"p1","prepMinutes":5,"vatRate":null}`), &p)
	out, err := json.Marshal(p)
	equal(t, err, nil)
	for _, part := range []string{`"id":"p1"`, `"prepMinutes":5`, `"vatRate":null`} {
		if !bytes.Contains(out, []byte(part)) {
			t.Fatalf("marshal = %s", out)
		}
	}
	if bytes.Contains(out, []byte("RawJSON")) || bytes.Contains(out, []byte("modifierGroups")) {
		t.Fatalf("marshal = %s", out)
	}
}
