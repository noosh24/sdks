package noosh24

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"strconv"
	"strings"
)

const (
	pageSizeDefault  = 100
	pageSizeBills    = 50
	pageSizeExpanded = 50
)

type MenuService struct{ c *Client }

func (s *MenuService) ListCategories(ctx context.Context) ([]Category, error) {
	return fetchAll[Category](ctx, s.c, "/menu/categories")
}

func (s *MenuService) ListProducts(ctx context.Context, params *ListParams) (*Page[Product], error) {
	return fetchPage[Product](ctx, s.c, "/menu/products", params.clone(), pageOptions{expand: true})
}

func (s *MenuService) IterateProducts(ctx context.Context, params *ListParams) iter.Seq2[Product, error] {
	size := pageSizeDefault
	if params != nil && len(expandQuery(params.Expand)) > 0 {
		size = pageSizeExpanded
	}
	return iterate[Product](ctx, s.c, "/menu/products", params, size, pageOptions{expand: true})
}

func (s *MenuService) GetProduct(ctx context.Context, id string, expand ...Expand) (*Product, error) {
	path, err := idPath("/menu/products/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Product](ctx, s.c, path, expandQuery(expand))
}

func (s *MenuService) GetStopList(ctx context.Context) ([]StopListItem, error) {
	return fetchAll[StopListItem](ctx, s.c, "/menu/stop-list")
}

type ReservationsService struct{ c *Client }

type PreOrderLine struct {
	ItemID string `json:"itemId"`
	Qty    int    `json:"qty"`
	Note   string `json:"note,omitempty"`
}

type NewReservation struct {
	Date           string         `json:"date"`
	Time           string         `json:"time"`
	Guests         int            `json:"guests"`
	GuestName      string         `json:"guestName"`
	Phone          string         `json:"phone"`
	Email          string         `json:"email,omitempty"`
	TableID        string         `json:"tableId,omitempty"`
	Zone           string         `json:"zone,omitempty"`
	SpecialRequest string         `json:"specialRequest,omitempty"`
	AllergyNote    string         `json:"allergyNote,omitempty"`
	Birthday       *bool          `json:"birthday,omitempty"`
	ChildChair     *bool          `json:"childChair,omitempty"`
	PreOrder       []PreOrderLine `json:"preOrder,omitzero"`
	ExternalRef    string         `json:"externalRef,omitempty"`
}

type CreateReservationResult struct {
	Reservation *Reservation
	Created     bool
}

func Bool(v bool) *bool {
	return &v
}

func (s *ReservationsService) List(ctx context.Context, params *ListParams) (*Page[Reservation], error) {
	return fetchPage[Reservation](ctx, s.c, "/reservations", params.clone(), pageOptions{})
}

func (s *ReservationsService) Iterate(ctx context.Context, params *ListParams) iter.Seq2[Reservation, error] {
	return iterate[Reservation](ctx, s.c, "/reservations", params, pageSizeDefault, pageOptions{})
}

func (s *ReservationsService) Get(ctx context.Context, id string) (*Reservation, error) {
	path, err := idPath("/reservations/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Reservation](ctx, s.c, path, nil)
}

func (s *ReservationsService) Availability(ctx context.Context, date, time string, guests int) (*TableAvailability, error) {
	query := []queryPair{{"date", date}, {"time", time}}
	if guests > 0 {
		query = append(query, queryPair{"guests", strconv.Itoa(guests)})
	}
	return getOne[TableAvailability](ctx, s.c, "/reservations/availability", query)
}

func (s *ReservationsService) Create(ctx context.Context, reservation *NewReservation) (*CreateReservationResult, error) {
	if reservation == nil {
		return nil, fmt.Errorf("%w: a reservation is required", ErrInvalidArgument)
	}
	idempotent := strings.TrimSpace(reservation.ExternalRef) != ""
	resp, err := s.c.do(ctx, request{method: "POST", path: "/reservations", body: reservation, retryable: idempotent})
	if err != nil {
		return nil, err
	}
	return &CreateReservationResult{Reservation: decodeOne[Reservation](resp.data), Created: resp.status == 201}, nil
}

func (s *ReservationsService) Cancel(ctx context.Context, id string) (*Reservation, error) {
	path, err := idPath("/reservations/", id, "/cancel")
	if err != nil {
		return nil, err
	}
	resp, err := s.c.do(ctx, request{method: "POST", path: path, retryable: true})
	if err != nil {
		return nil, err
	}
	return decodeOne[Reservation](resp.data), nil
}

type OrdersService struct{ c *Client }

func (s *OrdersService) List(ctx context.Context, params *ListParams) (*Page[Order], error) {
	return fetchPage[Order](ctx, s.c, "/orders", params.clone(), pageOptions{})
}

func (s *OrdersService) Iterate(ctx context.Context, params *ListParams) iter.Seq2[Order, error] {
	return iterate[Order](ctx, s.c, "/orders", params, pageSizeDefault, pageOptions{})
}

func (s *OrdersService) Get(ctx context.Context, id string) (*Order, error) {
	path, err := idPath("/orders/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Order](ctx, s.c, path, nil)
}

func (s *OrdersService) ListBills(ctx context.Context, params *ListParams) (*Page[Bill], error) {
	return fetchPage[Bill](ctx, s.c, "/bills", params.clone(), pageOptions{})
}

func (s *OrdersService) IterateBills(ctx context.Context, params *ListParams) iter.Seq2[Bill, error] {
	return iterate[Bill](ctx, s.c, "/bills", params, pageSizeBills, pageOptions{})
}

func (s *OrdersService) GetBill(ctx context.Context, id string) (*Bill, error) {
	path, err := idPath("/bills/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Bill](ctx, s.c, path, nil)
}

type PaymentsService struct{ c *Client }

type ZReport map[string]any

func (s *PaymentsService) List(ctx context.Context, params *ListParams) (*Page[Payment], error) {
	return fetchPage[Payment](ctx, s.c, "/payments", params.clone(), pageOptions{})
}

func (s *PaymentsService) Iterate(ctx context.Context, params *ListParams) iter.Seq2[Payment, error] {
	return iterate[Payment](ctx, s.c, "/payments", params, pageSizeDefault, pageOptions{})
}

func (s *PaymentsService) Get(ctx context.Context, id string) (*Payment, error) {
	path, err := idPath("/payments/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Payment](ctx, s.c, path, nil)
}

func (s *PaymentsService) ZReport(ctx context.Context, date string) (ZReport, error) {
	var query []queryPair
	if date != "" {
		query = append(query, queryPair{"date", date})
	}
	resp, err := s.c.do(ctx, request{method: "GET", path: "/reports/z", query: query, retryable: true})
	if err != nil {
		return nil, err
	}
	report := ZReport{}
	if isObject(resp.data) {
		_ = json.Unmarshal(resp.data, &report)
	}
	return report, nil
}

type TablesService struct{ c *Client }

func (s *TablesService) List(ctx context.Context) ([]Table, error) {
	return fetchAll[Table](ctx, s.c, "/tables")
}

func (s *TablesService) ListHalls(ctx context.Context) ([]Hall, error) {
	return fetchAll[Hall](ctx, s.c, "/halls")
}

type CustomersService struct{ c *Client }

func (s *CustomersService) List(ctx context.Context, params *ListParams) (*Page[Customer], error) {
	return fetchPage[Customer](ctx, s.c, "/customers", params.clone(), pageOptions{})
}

func (s *CustomersService) Iterate(ctx context.Context, params *ListParams) iter.Seq2[Customer, error] {
	return iterate[Customer](ctx, s.c, "/customers", params, pageSizeDefault, pageOptions{})
}

func (s *CustomersService) Get(ctx context.Context, id string) (*Customer, error) {
	path, err := idPath("/customers/", id, "")
	if err != nil {
		return nil, err
	}
	return getOne[Customer](ctx, s.c, path, nil)
}

type LoyaltyService struct{ c *Client }

func (s *LoyaltyService) GetProgram(ctx context.Context) (*LoyaltyProgram, error) {
	return getOne[LoyaltyProgram](ctx, s.c, "/loyalty/program", nil)
}

func (s *LoyaltyService) ListCards(ctx context.Context, params *ListParams) (*Page[LoyaltyCard], error) {
	return fetchPage[LoyaltyCard](ctx, s.c, "/loyalty/cards", params.clone(), pageOptions{})
}

func (s *LoyaltyService) IterateCards(ctx context.Context, params *ListParams) iter.Seq2[LoyaltyCard, error] {
	return iterate[LoyaltyCard](ctx, s.c, "/loyalty/cards", params, pageSizeDefault, pageOptions{})
}

type StockService struct{ c *Client }

func (s *StockService) ListIngredients(ctx context.Context, params *ListParams) (*Page[Ingredient], error) {
	return fetchPage[Ingredient](ctx, s.c, "/stock/ingredients", params.clone(), pageOptions{})
}

func (s *StockService) IterateIngredients(ctx context.Context, params *ListParams) iter.Seq2[Ingredient, error] {
	return iterate[Ingredient](ctx, s.c, "/stock/ingredients", params, pageSizeDefault, pageOptions{})
}

func (s *StockService) ListMoves(ctx context.Context, params *ListParams) (*Page[StockMove], error) {
	return fetchPage[StockMove](ctx, s.c, "/stock/moves", params.clone(), pageOptions{})
}

func (s *StockService) IterateMoves(ctx context.Context, params *ListParams) iter.Seq2[StockMove, error] {
	return iterate[StockMove](ctx, s.c, "/stock/moves", params, pageSizeDefault, pageOptions{})
}

func (s *StockService) ListStores(ctx context.Context) ([]StockStore, error) {
	return fetchAll[StockStore](ctx, s.c, "/stock/stores")
}

type ReviewsService struct{ c *Client }

func (s *ReviewsService) List(ctx context.Context, params *ListParams) (*Page[Review], error) {
	return fetchPage[Review](ctx, s.c, "/reviews", params.clone(), pageOptions{})
}

func (s *ReviewsService) Iterate(ctx context.Context, params *ListParams) iter.Seq2[Review, error] {
	return iterate[Review](ctx, s.c, "/reviews", params, pageSizeDefault, pageOptions{})
}

func idPath(prefix, id, suffix string) (string, error) {
	escaped, err := pathID(id)
	if err != nil {
		return "", err
	}
	return prefix + escaped + suffix, nil
}
