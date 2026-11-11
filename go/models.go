package noosh24

import (
	"encoding/json"
	"time"
)

type ReservationStatus string

const (
	ReservationStatusPending   ReservationStatus = "pending"
	ReservationStatusConfirmed ReservationStatus = "confirmed"
	ReservationStatusArriving  ReservationStatus = "arriving"
	ReservationStatusCheckedIn ReservationStatus = "checked_in"
	ReservationStatusCompleted ReservationStatus = "completed"
	ReservationStatusCancelled ReservationStatus = "cancelled"
	ReservationStatusNoShow    ReservationStatus = "no_show"
)

type ReservationSource string

const (
	ReservationSourceNoosh24 ReservationSource = "noosh24"
	ReservationSourceOpenApi ReservationSource = "open_api"
)

type OrderKind string

const (
	OrderKindTable    OrderKind = "table"
	OrderKindCounter  OrderKind = "counter"
	OrderKindDelivery OrderKind = "delivery"
)

type OrderStatus string

const (
	OrderStatusPendingWaiter OrderStatus = "pending_waiter"
	OrderStatusNew           OrderStatus = "new"
	OrderStatusAccepted      OrderStatus = "accepted"
	OrderStatusPreparing     OrderStatus = "preparing"
	OrderStatusReady         OrderStatus = "ready"
	OrderStatusServed        OrderStatus = "served"
	OrderStatusCancelled     OrderStatus = "cancelled"
)

type OrderItemStatus string

const (
	OrderItemStatusNew       OrderItemStatus = "new"
	OrderItemStatusPreparing OrderItemStatus = "preparing"
	OrderItemStatusReady     OrderItemStatus = "ready"
	OrderItemStatusCancelled OrderItemStatus = "cancelled"
)

type BillStatus string

const (
	BillStatusOpen          BillStatus = "open"
	BillStatusBillRequested BillStatus = "bill_requested"
	BillStatusPaid          BillStatus = "paid"
	BillStatusClosed        BillStatus = "closed"
	BillStatusAbandoned     BillStatus = "abandoned"
	BillStatusMerged        BillStatus = "merged"
)

type PaymentStatus string

const (
	PaymentStatusPending        PaymentStatus = "pending"
	PaymentStatusRequiresAction PaymentStatus = "requires_action"
	PaymentStatusSucceeded      PaymentStatus = "succeeded"
	PaymentStatusFailed         PaymentStatus = "failed"
	PaymentStatusRefunded       PaymentStatus = "refunded"
)

type PaymentMethod string

const (
	PaymentMethodCard      PaymentMethod = "card"
	PaymentMethodApplePay  PaymentMethod = "apple_pay"
	PaymentMethodGooglePay PaymentMethod = "google_pay"
	PaymentMethodAzqr      PaymentMethod = "azqr"
	PaymentMethodCash      PaymentMethod = "cash"
	PaymentMethodBirbank   PaymentMethod = "birbank"
	PaymentMethodPlatform  PaymentMethod = "platform"
)

type PaymentTakenAt string

const (
	PaymentTakenAtTill  PaymentTakenAt = "till"
	PaymentTakenAtGuest PaymentTakenAt = "guest"
)

type TableStatus string

const (
	TableStatusAvailable TableStatus = "available"
	TableStatusReserved  TableStatus = "reserved"
	TableStatusOccupied  TableStatus = "occupied"
	TableStatusCleaning  TableStatus = "cleaning"
	TableStatusPayment   TableStatus = "payment"
)

type LoyaltyProgramEarnBy string

const (
	LoyaltyProgramEarnByVisit LoyaltyProgramEarnBy = "visit"
	LoyaltyProgramEarnByItems LoyaltyProgramEarnBy = "items"
)

type LoyaltyProgramRewardScope string

const (
	LoyaltyProgramRewardScopeAll        LoyaltyProgramRewardScope = "all"
	LoyaltyProgramRewardScopeCategories LoyaltyProgramRewardScope = "categories"
	LoyaltyProgramRewardScopeItems      LoyaltyProgramRewardScope = "items"
)

type LoyaltyCardSource string

const (
	LoyaltyCardSourcePanel LoyaltyCardSource = "panel"
	LoyaltyCardSourceTill  LoyaltyCardSource = "till"
	LoyaltyCardSourceWeb   LoyaltyCardSource = "web"
	LoyaltyCardSourceApp   LoyaltyCardSource = "app"
)

type IngredientState string

const (
	IngredientStateOk    IngredientState = "ok"
	IngredientStateLow   IngredientState = "low"
	IngredientStateEmpty IngredientState = "empty"
)

type SubscriptionStatus string

const (
	SubscriptionStatusNone       SubscriptionStatus = "none"
	SubscriptionStatusTrial      SubscriptionStatus = "trial"
	SubscriptionStatusActive     SubscriptionStatus = "active"
	SubscriptionStatusExpiring   SubscriptionStatus = "expiring"
	SubscriptionStatusGrace      SubscriptionStatus = "grace"
	SubscriptionStatusRestricted SubscriptionStatus = "restricted"
	SubscriptionStatusSuspended  SubscriptionStatus = "suspended"
)

type Restaurant struct {
	ID      string          `json:"id"`
	Name    string          `json:"name"`
	Slug    string          `json:"slug"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *Restaurant) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Restaurant{}
		return nil
	}
	*m = Restaurant{
		ID:      stringValue(f["id"]),
		Name:    stringValue(f["name"]),
		Slug:    stringValue(f["slug"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type ApiKeyInfo struct {
	ID      string          `json:"id"`
	Name    string          `json:"name"`
	Prefix  string          `json:"prefix"`
	Scopes  []string        `json:"scopes"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *ApiKeyInfo) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ApiKeyInfo{}
		return nil
	}
	*m = ApiKeyInfo{
		ID:      stringValue(f["id"]),
		Name:    stringValue(f["name"]),
		Prefix:  stringValue(f["prefix"]),
		Scopes:  stringList(f["scopes"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type Subscription struct {
	Status  SubscriptionStatus `json:"status"`
	Modules []string           `json:"modules"`
	RawJSON json.RawMessage    `json:"-"`
}

func (m *Subscription) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Subscription{}
		return nil
	}
	*m = Subscription{
		Status:  SubscriptionStatus(stringValue(f["status"])),
		Modules: stringList(f["modules"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type Features struct {
	Loyalty   bool            `json:"loyalty"`
	Inventory bool            `json:"inventory"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *Features) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Features{}
		return nil
	}
	*m = Features{
		Loyalty:   boolValue(f["loyalty"]),
		Inventory: boolValue(f["inventory"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type Whoami struct {
	Restaurant   *Restaurant     `json:"restaurant"`
	Key          *ApiKeyInfo     `json:"key"`
	Subscription *Subscription   `json:"subscription"`
	Features     *Features       `json:"features"`
	RawJSON      json.RawMessage `json:"-"`
}

func (m *Whoami) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Whoami{}
		return nil
	}
	*m = Whoami{
		Restaurant:   object[Restaurant](f["restaurant"]),
		Key:          object[ApiKeyInfo](f["key"]),
		Subscription: object[Subscription](f["subscription"]),
		Features:     object[Features](f["features"]),
		RawJSON:      cloneRaw(data),
	}
	return nil
}

type Category struct {
	Name      string          `json:"name"`
	Position  int             `json:"position"`
	Products  int             `json:"products"`
	Available int             `json:"available"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *Category) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Category{}
		return nil
	}
	*m = Category{
		Name:      stringValue(f["name"]),
		Position:  intValue(f["position"]),
		Products:  intValue(f["products"]),
		Available: intValue(f["available"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type Modifier struct {
	ID         string          `json:"id"`
	Name       string          `json:"name"`
	PriceDelta float64         `json:"priceDelta"`
	Position   int             `json:"position"`
	RawJSON    json.RawMessage `json:"-"`
}

func (m *Modifier) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Modifier{}
		return nil
	}
	*m = Modifier{
		ID:         stringValue(f["id"]),
		Name:       stringValue(f["name"]),
		PriceDelta: floatValue(f["priceDelta"]),
		Position:   intValue(f["position"]),
		RawJSON:    cloneRaw(data),
	}
	return nil
}

type ModifierGroup struct {
	ID        string          `json:"id"`
	Name      string          `json:"name"`
	Required  bool            `json:"required"`
	Position  int             `json:"position"`
	Modifiers []Modifier      `json:"modifiers"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *ModifierGroup) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ModifierGroup{}
		return nil
	}
	*m = ModifierGroup{
		ID:        stringValue(f["id"]),
		Name:      stringValue(f["name"]),
		Required:  boolValue(f["required"]),
		Position:  intValue(f["position"]),
		Modifiers: listOf[Modifier](f["modifiers"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type ProductTranslation struct {
	Name        string          `json:"name"`
	Description string          `json:"description"`
	RawJSON     json.RawMessage `json:"-"`
}

func (m *ProductTranslation) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ProductTranslation{}
		return nil
	}
	*m = ProductTranslation{
		Name:        stringValue(f["name"]),
		Description: stringValue(f["description"]),
		RawJSON:     cloneRaw(data),
	}
	return nil
}

type Product struct {
	ID             string                        `json:"id"`
	Name           string                        `json:"name"`
	Category       string                        `json:"category"`
	Description    string                        `json:"description"`
	Price          float64                       `json:"price"`
	Available      bool                          `json:"available"`
	Popular        bool                          `json:"popular"`
	Position       int                           `json:"position"`
	PrepMinutes    int                           `json:"prepMinutes"`
	Station        string                        `json:"station"`
	VatRate        *float64                      `json:"vatRate"`
	Vegetarian     bool                          `json:"vegetarian"`
	Spicy          bool                          `json:"spicy"`
	Allergens      []string                      `json:"allergens"`
	Discountable   bool                          `json:"discountable"`
	HasModifiers   bool                          `json:"hasModifiers"`
	Image          *string                       `json:"image"`
	Video          *string                       `json:"video"`
	ModifierGroups []ModifierGroup               `json:"modifierGroups,omitempty"`
	Translations   map[string]ProductTranslation `json:"translations,omitempty"`
	RawJSON        json.RawMessage               `json:"-"`
}

func (m *Product) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Product{}
		return nil
	}
	*m = Product{
		ID:             stringValue(f["id"]),
		Name:           stringValue(f["name"]),
		Category:       stringValue(f["category"]),
		Description:    stringValue(f["description"]),
		Price:          floatValue(f["price"]),
		Available:      boolValue(f["available"]),
		Popular:        boolValue(f["popular"]),
		Position:       intValue(f["position"]),
		PrepMinutes:    intValue(f["prepMinutes"]),
		Station:        stringValue(f["station"]),
		VatRate:        floatPtr(f["vatRate"]),
		Vegetarian:     boolValue(f["vegetarian"]),
		Spicy:          boolValue(f["spicy"]),
		Allergens:      stringList(f["allergens"]),
		Discountable:   boolValue(f["discountable"]),
		HasModifiers:   boolValue(f["hasModifiers"]),
		Image:          stringPtr(f["image"]),
		Video:          stringPtr(f["video"]),
		ModifierGroups: listOf[ModifierGroup](f["modifierGroups"]),
		Translations:   mapOf[ProductTranslation](f["translations"]),
		RawJSON:        cloneRaw(data),
	}
	return nil
}

type StopListItem struct {
	ID       string          `json:"id"`
	Name     string          `json:"name"`
	Category string          `json:"category"`
	Price    float64         `json:"price"`
	RawJSON  json.RawMessage `json:"-"`
}

func (m *StopListItem) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = StopListItem{}
		return nil
	}
	*m = StopListItem{
		ID:       stringValue(f["id"]),
		Name:     stringValue(f["name"]),
		Category: stringValue(f["category"]),
		Price:    floatValue(f["price"]),
		RawJSON:  cloneRaw(data),
	}
	return nil
}

type ReservationGuest struct {
	Name    string          `json:"name"`
	Phone   string          `json:"phone"`
	Email   *string         `json:"email"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *ReservationGuest) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ReservationGuest{}
		return nil
	}
	*m = ReservationGuest{
		Name:    stringValue(f["name"]),
		Phone:   stringValue(f["phone"]),
		Email:   stringPtr(f["email"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type ReservationTable struct {
	ID      string          `json:"id"`
	Label   string          `json:"label"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *ReservationTable) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ReservationTable{}
		return nil
	}
	*m = ReservationTable{
		ID:      stringValue(f["id"]),
		Label:   stringValue(f["label"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type ReservationPreOrderItem struct {
	ProductID *string         `json:"productId"`
	Name      string          `json:"name"`
	Price     float64         `json:"price"`
	Qty       int             `json:"qty"`
	Note      *string         `json:"note"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *ReservationPreOrderItem) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ReservationPreOrderItem{}
		return nil
	}
	*m = ReservationPreOrderItem{
		ProductID: stringPtr(f["productId"]),
		Name:      stringValue(f["name"]),
		Price:     floatValue(f["price"]),
		Qty:       intValue(f["qty"]),
		Note:      stringPtr(f["note"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type Reservation struct {
	ID             string                    `json:"id"`
	Code           string                    `json:"code"`
	Status         ReservationStatus         `json:"status"`
	Source         ReservationSource         `json:"source"`
	StartsAt       time.Time                 `json:"startsAt"`
	EndsAt         time.Time                 `json:"endsAt"`
	Guests         int                       `json:"guests"`
	Zone           string                    `json:"zone"`
	Table          *ReservationTable         `json:"table"`
	Guest          *ReservationGuest         `json:"guest"`
	SpecialRequest *string                   `json:"specialRequest"`
	AllergyNote    *string                   `json:"allergyNote"`
	Birthday       bool                      `json:"birthday"`
	ChildChair     bool                      `json:"childChair"`
	DepositPaid    float64                   `json:"depositPaid"`
	PreOrder       []ReservationPreOrderItem `json:"preOrder"`
	ExternalRef    *string                   `json:"externalRef"`
	DecidedAt      *time.Time                `json:"decidedAt"`
	CreatedAt      time.Time                 `json:"createdAt"`
	UpdatedAt      time.Time                 `json:"updatedAt"`
	RawJSON        json.RawMessage           `json:"-"`
}

func (m *Reservation) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Reservation{}
		return nil
	}
	*m = Reservation{
		ID:             stringValue(f["id"]),
		Code:           stringValue(f["code"]),
		Status:         ReservationStatus(stringValue(f["status"])),
		Source:         ReservationSource(stringValue(f["source"])),
		StartsAt:       timeValue(f["startsAt"]),
		EndsAt:         timeValue(f["endsAt"]),
		Guests:         intValue(f["guests"]),
		Zone:           stringValue(f["zone"]),
		Table:          object[ReservationTable](f["table"]),
		Guest:          object[ReservationGuest](f["guest"]),
		SpecialRequest: stringPtr(f["specialRequest"]),
		AllergyNote:    stringPtr(f["allergyNote"]),
		Birthday:       boolValue(f["birthday"]),
		ChildChair:     boolValue(f["childChair"]),
		DepositPaid:    floatValue(f["depositPaid"]),
		PreOrder:       listOf[ReservationPreOrderItem](f["preOrder"]),
		ExternalRef:    stringPtr(f["externalRef"]),
		DecidedAt:      timePtr(f["decidedAt"]),
		CreatedAt:      timeValue(f["createdAt"]),
		UpdatedAt:      timeValue(f["updatedAt"]),
		RawJSON:        cloneRaw(data),
	}
	return nil
}

type AvailableTable struct {
	ID      string          `json:"id"`
	Label   string          `json:"label"`
	HallID  string          `json:"hallId"`
	Zone    string          `json:"zone"`
	Seats   int             `json:"seats"`
	Free    bool            `json:"free"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *AvailableTable) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = AvailableTable{}
		return nil
	}
	*m = AvailableTable{
		ID:      stringValue(f["id"]),
		Label:   stringValue(f["label"]),
		HallID:  stringValue(f["hallId"]),
		Zone:    stringValue(f["zone"]),
		Seats:   intValue(f["seats"]),
		Free:    boolValue(f["free"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type TableAvailability struct {
	StartsAt        time.Time        `json:"startsAt"`
	EndsAt          time.Time        `json:"endsAt"`
	DurationMinutes int              `json:"durationMinutes"`
	OpenTime        string           `json:"openTime"`
	CloseTime       string           `json:"closeTime"`
	Tables          []AvailableTable `json:"tables"`
	RawJSON         json.RawMessage  `json:"-"`
}

func (m *TableAvailability) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = TableAvailability{}
		return nil
	}
	*m = TableAvailability{
		StartsAt:        timeValue(f["startsAt"]),
		EndsAt:          timeValue(f["endsAt"]),
		DurationMinutes: intValue(f["durationMinutes"]),
		OpenTime:        stringValue(f["openTime"]),
		CloseTime:       stringValue(f["closeTime"]),
		Tables:          listOf[AvailableTable](f["tables"]),
		RawJSON:         cloneRaw(data),
	}
	return nil
}

type OrderItem struct {
	ID           string          `json:"id"`
	ProductID    *string         `json:"productId"`
	Name         string          `json:"name"`
	Qty          int             `json:"qty"`
	Price        float64         `json:"price"`
	ListPrice    *float64        `json:"listPrice"`
	Modifiers    *string         `json:"modifiers"`
	Note         *string         `json:"note"`
	Status       OrderItemStatus `json:"status"`
	Comp         bool            `json:"comp"`
	Campaign     *string         `json:"campaign"`
	CancelReason *string         `json:"cancelReason"`
	RawJSON      json.RawMessage `json:"-"`
}

func (m *OrderItem) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = OrderItem{}
		return nil
	}
	*m = OrderItem{
		ID:           stringValue(f["id"]),
		ProductID:    stringPtr(f["productId"]),
		Name:         stringValue(f["name"]),
		Qty:          intValue(f["qty"]),
		Price:        floatValue(f["price"]),
		ListPrice:    floatPtr(f["listPrice"]),
		Modifiers:    stringPtr(f["modifiers"]),
		Note:         stringPtr(f["note"]),
		Status:       OrderItemStatus(stringValue(f["status"])),
		Comp:         boolValue(f["comp"]),
		Campaign:     stringPtr(f["campaign"]),
		CancelReason: stringPtr(f["cancelReason"]),
		RawJSON:      cloneRaw(data),
	}
	return nil
}

type DeliveryPlatform struct {
	ID      *string         `json:"id"`
	Name    *string         `json:"name"`
	Ref     *string         `json:"ref"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *DeliveryPlatform) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = DeliveryPlatform{}
		return nil
	}
	*m = DeliveryPlatform{
		ID:      stringPtr(f["id"]),
		Name:    stringPtr(f["name"]),
		Ref:     stringPtr(f["ref"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type OrderDelivery struct {
	Status        *string           `json:"status"`
	Platform      *DeliveryPlatform `json:"platform"`
	Address       *string           `json:"address"`
	CustomerPhone *string           `json:"customerPhone"`
	CourierName   *string           `json:"courierName"`
	Note          *string           `json:"note"`
	PaymentMethod *string           `json:"paymentMethod"`
	Fee           *float64          `json:"fee"`
	PlatformTotal *float64          `json:"platformTotal"`
	AcceptedAt    *time.Time        `json:"acceptedAt"`
	RawJSON       json.RawMessage   `json:"-"`
}

func (m *OrderDelivery) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = OrderDelivery{}
		return nil
	}
	*m = OrderDelivery{
		Status:        stringPtr(f["status"]),
		Platform:      object[DeliveryPlatform](f["platform"]),
		Address:       stringPtr(f["address"]),
		CustomerPhone: stringPtr(f["customerPhone"]),
		CourierName:   stringPtr(f["courierName"]),
		Note:          stringPtr(f["note"]),
		PaymentMethod: stringPtr(f["paymentMethod"]),
		Fee:           floatPtr(f["fee"]),
		PlatformTotal: floatPtr(f["platformTotal"]),
		AcceptedAt:    timePtr(f["acceptedAt"]),
		RawJSON:       cloneRaw(data),
	}
	return nil
}

type Order struct {
	ID           string          `json:"id"`
	Number       string          `json:"number"`
	DailyNumber  *int            `json:"dailyNumber"`
	Kind         OrderKind       `json:"kind"`
	OrderType    *string         `json:"orderType"`
	Status       OrderStatus     `json:"status"`
	TableID      string          `json:"tableId"`
	BillID       string          `json:"billId"`
	CustomerName *string         `json:"customerName"`
	AllergyNote  *string         `json:"allergyNote"`
	Items        []OrderItem     `json:"items"`
	Subtotal     float64         `json:"subtotal"`
	Delivery     *OrderDelivery  `json:"delivery"`
	CreatedAt    time.Time       `json:"createdAt"`
	UpdatedAt    time.Time       `json:"updatedAt"`
	RawJSON      json.RawMessage `json:"-"`
}

func (m *Order) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Order{}
		return nil
	}
	*m = Order{
		ID:           stringValue(f["id"]),
		Number:       stringValue(f["number"]),
		DailyNumber:  intPtr(f["dailyNumber"]),
		Kind:         OrderKind(stringValue(f["kind"])),
		OrderType:    stringPtr(f["orderType"]),
		Status:       OrderStatus(stringValue(f["status"])),
		TableID:      stringValue(f["tableId"]),
		BillID:       stringValue(f["billId"]),
		CustomerName: stringPtr(f["customerName"]),
		AllergyNote:  stringPtr(f["allergyNote"]),
		Items:        listOf[OrderItem](f["items"]),
		Subtotal:     floatValue(f["subtotal"]),
		Delivery:     object[OrderDelivery](f["delivery"]),
		CreatedAt:    timeValue(f["createdAt"]),
		UpdatedAt:    timeValue(f["updatedAt"]),
		RawJSON:      cloneRaw(data),
	}
	return nil
}

type Bill struct {
	ID                string          `json:"id"`
	TableID           string          `json:"tableId"`
	Status            BillStatus      `json:"status"`
	Guests            int             `json:"guests"`
	Waiter            *string         `json:"waiter"`
	CustomerID        *string         `json:"customerId"`
	ReservationID     *string         `json:"reservationId"`
	OrderIDs          []string        `json:"orderIds"`
	Subtotal          float64         `json:"subtotal"`
	DiscountPercent   float64         `json:"discountPercent"`
	BillDiscount      float64         `json:"billDiscount"`
	ServiceFeePercent float64         `json:"serviceFeePercent"`
	ServiceFee        float64         `json:"serviceFee"`
	Total             float64         `json:"total"`
	Paid              float64         `json:"paid"`
	Remaining         float64         `json:"remaining"`
	OpenedAt          time.Time       `json:"openedAt"`
	ClosedAt          *time.Time      `json:"closedAt"`
	RawJSON           json.RawMessage `json:"-"`
}

func (m *Bill) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Bill{}
		return nil
	}
	*m = Bill{
		ID:                stringValue(f["id"]),
		TableID:           stringValue(f["tableId"]),
		Status:            BillStatus(stringValue(f["status"])),
		Guests:            intValue(f["guests"]),
		Waiter:            stringPtr(f["waiter"]),
		CustomerID:        stringPtr(f["customerId"]),
		ReservationID:     stringPtr(f["reservationId"]),
		OrderIDs:          stringList(f["orderIds"]),
		Subtotal:          floatValue(f["subtotal"]),
		DiscountPercent:   floatValue(f["discountPercent"]),
		BillDiscount:      floatValue(f["billDiscount"]),
		ServiceFeePercent: floatValue(f["serviceFeePercent"]),
		ServiceFee:        floatValue(f["serviceFee"]),
		Total:             floatValue(f["total"]),
		Paid:              floatValue(f["paid"]),
		Remaining:         floatValue(f["remaining"]),
		OpenedAt:          timeValue(f["openedAt"]),
		ClosedAt:          timePtr(f["closedAt"]),
		RawJSON:           cloneRaw(data),
	}
	return nil
}

type PaymentCard struct {
	MaskedPan string          `json:"maskedPan"`
	Scheme    string          `json:"scheme"`
	Bank      string          `json:"bank"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *PaymentCard) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = PaymentCard{}
		return nil
	}
	*m = PaymentCard{
		MaskedPan: stringValue(f["maskedPan"]),
		Scheme:    stringValue(f["scheme"]),
		Bank:      stringValue(f["bank"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type PaymentPlatform struct {
	ID      string          `json:"id"`
	Name    *string         `json:"name"`
	RawJSON json.RawMessage `json:"-"`
}

func (m *PaymentPlatform) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = PaymentPlatform{}
		return nil
	}
	*m = PaymentPlatform{
		ID:      stringValue(f["id"]),
		Name:    stringPtr(f["name"]),
		RawJSON: cloneRaw(data),
	}
	return nil
}

type Payment struct {
	ID             string           `json:"id"`
	Status         PaymentStatus    `json:"status"`
	Method         PaymentMethod    `json:"method"`
	RecordedMethod string           `json:"recordedMethod"`
	Amount         float64          `json:"amount"`
	Tip            float64          `json:"tip"`
	RefundedAmount *float64         `json:"refundedAmount"`
	RefundedAt     *time.Time       `json:"refundedAt"`
	RefundReason   *string          `json:"refundReason"`
	BillID         *string          `json:"billId"`
	ReservationID  *string          `json:"reservationId"`
	OrderID        *string          `json:"orderId"`
	TakenAt        PaymentTakenAt   `json:"takenAt"`
	Card           *PaymentCard     `json:"card"`
	Platform       *PaymentPlatform `json:"platform"`
	CreatedAt      time.Time        `json:"createdAt"`
	SettledAt      *time.Time       `json:"settledAt"`
	RawJSON        json.RawMessage  `json:"-"`
}

func (m *Payment) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Payment{}
		return nil
	}
	*m = Payment{
		ID:             stringValue(f["id"]),
		Status:         PaymentStatus(stringValue(f["status"])),
		Method:         PaymentMethod(stringValue(f["method"])),
		RecordedMethod: stringValue(f["recordedMethod"]),
		Amount:         floatValue(f["amount"]),
		Tip:            floatValue(f["tip"]),
		RefundedAmount: floatPtr(f["refundedAmount"]),
		RefundedAt:     timePtr(f["refundedAt"]),
		RefundReason:   stringPtr(f["refundReason"]),
		BillID:         stringPtr(f["billId"]),
		ReservationID:  stringPtr(f["reservationId"]),
		OrderID:        stringPtr(f["orderId"]),
		TakenAt:        PaymentTakenAt(stringValue(f["takenAt"])),
		Card:           object[PaymentCard](f["card"]),
		Platform:       object[PaymentPlatform](f["platform"]),
		CreatedAt:      timeValue(f["createdAt"]),
		SettledAt:      timePtr(f["settledAt"]),
		RawJSON:        cloneRaw(data),
	}
	return nil
}

type Hall struct {
	ID       string          `json:"id"`
	Name     string          `json:"name"`
	Position int             `json:"position"`
	RawJSON  json.RawMessage `json:"-"`
}

func (m *Hall) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Hall{}
		return nil
	}
	*m = Hall{
		ID:       stringValue(f["id"]),
		Name:     stringValue(f["name"]),
		Position: intValue(f["position"]),
		RawJSON:  cloneRaw(data),
	}
	return nil
}

type Table struct {
	ID            string          `json:"id"`
	Label         string          `json:"label"`
	HallID        string          `json:"hallId"`
	Zone          string          `json:"zone"`
	Seats         int             `json:"seats"`
	Shape         string          `json:"shape"`
	Status        TableStatus     `json:"status"`
	Guests        *int            `json:"guests"`
	Waiter        *string         `json:"waiter"`
	SeatedSince   *string         `json:"seatedSince"`
	OpenOrders    int             `json:"openOrders"`
	BillID        *string         `json:"billId"`
	BillTotal     *float64        `json:"billTotal"`
	BillRequested bool            `json:"billRequested"`
	BillSettled   bool            `json:"billSettled"`
	MergedInto    *string         `json:"mergedInto"`
	RawJSON       json.RawMessage `json:"-"`
}

func (m *Table) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Table{}
		return nil
	}
	*m = Table{
		ID:            stringValue(f["id"]),
		Label:         stringValue(f["label"]),
		HallID:        stringValue(f["hallId"]),
		Zone:          stringValue(f["zone"]),
		Seats:         intValue(f["seats"]),
		Shape:         stringValue(f["shape"]),
		Status:        TableStatus(stringValue(f["status"])),
		Guests:        intPtr(f["guests"]),
		Waiter:        stringPtr(f["waiter"]),
		SeatedSince:   stringPtr(f["seatedSince"]),
		OpenOrders:    intValue(f["openOrders"]),
		BillID:        stringPtr(f["billId"]),
		BillTotal:     floatPtr(f["billTotal"]),
		BillRequested: boolValue(f["billRequested"]),
		BillSettled:   boolValue(f["billSettled"]),
		MergedInto:    stringPtr(f["mergedInto"]),
		RawJSON:       cloneRaw(data),
	}
	return nil
}

type Customer struct {
	ID        string          `json:"id"`
	Name      string          `json:"name"`
	Phone     string          `json:"phone"`
	Note      string          `json:"note"`
	CreatedAt time.Time       `json:"createdAt"`
	UpdatedAt time.Time       `json:"updatedAt"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *Customer) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Customer{}
		return nil
	}
	*m = Customer{
		ID:        stringValue(f["id"]),
		Name:      stringValue(f["name"]),
		Phone:     stringValue(f["phone"]),
		Note:      stringValue(f["note"]),
		CreatedAt: timeValue(f["createdAt"]),
		UpdatedAt: timeValue(f["updatedAt"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type LoyaltyProgram struct {
	StampsNeeded     int                       `json:"stampsNeeded"`
	EarnBy           LoyaltyProgramEarnBy      `json:"earnBy"`
	MinBill          float64                   `json:"minBill"`
	OncePerDay       bool                      `json:"oncePerDay"`
	RewardName       string                    `json:"rewardName"`
	RewardScope      LoyaltyProgramRewardScope `json:"rewardScope"`
	RewardCategories []string                  `json:"rewardCategories"`
	RewardProductIDs []string                  `json:"rewardProductIds"`
	RewardMaxPrice   float64                   `json:"rewardMaxPrice"`
	Terms            string                    `json:"terms"`
	RawJSON          json.RawMessage           `json:"-"`
}

func (m *LoyaltyProgram) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = LoyaltyProgram{}
		return nil
	}
	*m = LoyaltyProgram{
		StampsNeeded:     intValue(f["stampsNeeded"]),
		EarnBy:           LoyaltyProgramEarnBy(stringValue(f["earnBy"])),
		MinBill:          floatValue(f["minBill"]),
		OncePerDay:       boolValue(f["oncePerDay"]),
		RewardName:       stringValue(f["rewardName"]),
		RewardScope:      LoyaltyProgramRewardScope(stringValue(f["rewardScope"])),
		RewardCategories: stringList(f["rewardCategories"]),
		RewardProductIDs: stringList(f["rewardProductIds"]),
		RewardMaxPrice:   floatValue(f["rewardMaxPrice"]),
		Terms:            stringValue(f["terms"]),
		RawJSON:          cloneRaw(data),
	}
	return nil
}

type LoyaltyCard struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Phone       string            `json:"phone"`
	Stamps      int               `json:"stamps"`
	TotalStamps int               `json:"totalStamps"`
	Redeemed    int               `json:"redeemed"`
	Source      LoyaltyCardSource `json:"source"`
	LastVisitAt *time.Time        `json:"lastVisitAt"`
	CreatedAt   time.Time         `json:"createdAt"`
	UpdatedAt   time.Time         `json:"updatedAt"`
	RawJSON     json.RawMessage   `json:"-"`
}

func (m *LoyaltyCard) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = LoyaltyCard{}
		return nil
	}
	*m = LoyaltyCard{
		ID:          stringValue(f["id"]),
		Name:        stringValue(f["name"]),
		Phone:       stringValue(f["phone"]),
		Stamps:      intValue(f["stamps"]),
		TotalStamps: intValue(f["totalStamps"]),
		Redeemed:    intValue(f["redeemed"]),
		Source:      LoyaltyCardSource(stringValue(f["source"])),
		LastVisitAt: timePtr(f["lastVisitAt"]),
		CreatedAt:   timeValue(f["createdAt"]),
		UpdatedAt:   timeValue(f["updatedAt"]),
		RawJSON:     cloneRaw(data),
	}
	return nil
}

type Ingredient struct {
	ID          string             `json:"id"`
	Name        string             `json:"name"`
	Unit        string             `json:"unit"`
	Stock       float64            `json:"stock"`
	OnOpenBills float64            `json:"onOpenBills"`
	Available   float64            `json:"available"`
	State       IngredientState    `json:"state"`
	LowStock    float64            `json:"lowStock"`
	ParStock    float64            `json:"parStock"`
	CostPerUnit float64            `json:"costPerUnit"`
	Value       float64            `json:"value"`
	Prepared    bool               `json:"prepared"`
	ByStore     map[string]float64 `json:"byStore"`
	UpdatedAt   time.Time          `json:"updatedAt"`
	RawJSON     json.RawMessage    `json:"-"`
}

func (m *Ingredient) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Ingredient{}
		return nil
	}
	*m = Ingredient{
		ID:          stringValue(f["id"]),
		Name:        stringValue(f["name"]),
		Unit:        stringValue(f["unit"]),
		Stock:       floatValue(f["stock"]),
		OnOpenBills: floatValue(f["onOpenBills"]),
		Available:   floatValue(f["available"]),
		State:       IngredientState(stringValue(f["state"])),
		LowStock:    floatValue(f["lowStock"]),
		ParStock:    floatValue(f["parStock"]),
		CostPerUnit: floatValue(f["costPerUnit"]),
		Value:       floatValue(f["value"]),
		Prepared:    boolValue(f["prepared"]),
		ByStore:     floatMap(f["byStore"]),
		UpdatedAt:   timeValue(f["updatedAt"]),
		RawJSON:     cloneRaw(data),
	}
	return nil
}

type StockStore struct {
	ID        string          `json:"id"`
	Name      string          `json:"name"`
	IsDefault bool            `json:"isDefault"`
	Stations  []string        `json:"stations"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *StockStore) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = StockStore{}
		return nil
	}
	*m = StockStore{
		ID:        stringValue(f["id"]),
		Name:      stringValue(f["name"]),
		IsDefault: boolValue(f["isDefault"]),
		Stations:  stringList(f["stations"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}

type StockMove struct {
	ID           string          `json:"id"`
	IngredientID string          `json:"ingredientId"`
	Qty          float64         `json:"qty"`
	Reason       string          `json:"reason"`
	OrderID      *string         `json:"orderId"`
	InvoiceID    *string         `json:"invoiceId"`
	StoreID      *string         `json:"storeId"`
	Note         *string         `json:"note"`
	CreatedAt    time.Time       `json:"createdAt"`
	RawJSON      json.RawMessage `json:"-"`
}

func (m *StockMove) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = StockMove{}
		return nil
	}
	*m = StockMove{
		ID:           stringValue(f["id"]),
		IngredientID: stringValue(f["ingredientId"]),
		Qty:          floatValue(f["qty"]),
		Reason:       stringValue(f["reason"]),
		OrderID:      stringPtr(f["orderId"]),
		InvoiceID:    stringPtr(f["invoiceId"]),
		StoreID:      stringPtr(f["storeId"]),
		Note:         stringPtr(f["note"]),
		CreatedAt:    timeValue(f["createdAt"]),
		RawJSON:      cloneRaw(data),
	}
	return nil
}

type ReviewRatings struct {
	Food        float64         `json:"food"`
	Service     float64         `json:"service"`
	Atmosphere  float64         `json:"atmosphere"`
	Cleanliness float64         `json:"cleanliness"`
	Price       float64         `json:"price"`
	RawJSON     json.RawMessage `json:"-"`
}

func (m *ReviewRatings) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = ReviewRatings{}
		return nil
	}
	*m = ReviewRatings{
		Food:        floatValue(f["food"]),
		Service:     floatValue(f["service"]),
		Atmosphere:  floatValue(f["atmosphere"]),
		Cleanliness: floatValue(f["cleanliness"]),
		Price:       floatValue(f["price"]),
		RawJSON:     cloneRaw(data),
	}
	return nil
}

type Review struct {
	ID        string          `json:"id"`
	Author    string          `json:"author"`
	Overall   float64         `json:"overall"`
	Ratings   *ReviewRatings  `json:"ratings"`
	Body      string          `json:"body"`
	VisitType string          `json:"visitType"`
	VisitedOn time.Time       `json:"visitedOn"`
	Verified  bool            `json:"verified"`
	Reply     *string         `json:"reply"`
	RepliedAt *time.Time      `json:"repliedAt"`
	CreatedAt time.Time       `json:"createdAt"`
	RawJSON   json.RawMessage `json:"-"`
}

func (m *Review) UnmarshalJSON(data []byte) error {
	f, ok := objectFields(data)
	if !ok {
		*m = Review{}
		return nil
	}
	*m = Review{
		ID:        stringValue(f["id"]),
		Author:    stringValue(f["author"]),
		Overall:   floatValue(f["overall"]),
		Ratings:   object[ReviewRatings](f["ratings"]),
		Body:      stringValue(f["body"]),
		VisitType: stringValue(f["visitType"]),
		VisitedOn: timeValue(f["visitedOn"]),
		Verified:  boolValue(f["verified"]),
		Reply:     stringPtr(f["reply"]),
		RepliedAt: timePtr(f["repliedAt"]),
		CreatedAt: timeValue(f["createdAt"]),
		RawJSON:   cloneRaw(data),
	}
	return nil
}
