from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from ._convert import _bool, _datetime, _float, _floats, _int, _list_of, _map_of, _object, _str, _strings

__all__ = [
    "Restaurant",
    "ApiKeyInfo",
    "Subscription",
    "Features",
    "Whoami",
    "Category",
    "Modifier",
    "ModifierGroup",
    "ProductTranslation",
    "Product",
    "StopListItem",
    "ReservationGuest",
    "ReservationTable",
    "ReservationPreOrderItem",
    "Reservation",
    "AvailableTable",
    "TableAvailability",
    "OrderItem",
    "DeliveryPlatform",
    "OrderDelivery",
    "Order",
    "Bill",
    "PaymentCard",
    "PaymentPlatform",
    "Payment",
    "Hall",
    "Table",
    "Customer",
    "LoyaltyProgram",
    "LoyaltyCard",
    "Ingredient",
    "StockStore",
    "StockMove",
    "ReviewRatings",
    "Review",
]


@dataclass(frozen=True, slots=True, kw_only=True)
class Restaurant:
    id: str | None = None
    name: str | None = None
    slug: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Restaurant:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            slug=_str(data.get("slug")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ApiKeyInfo:
    id: str | None = None
    name: str | None = None
    prefix: str | None = None
    scopes: list[str] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ApiKeyInfo:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            prefix=_str(data.get("prefix")),
            scopes=_strings(data.get("scopes")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Subscription:
    status: str | None = None
    modules: list[str] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Subscription:
        return cls(
            status=_str(data.get("status")),
            modules=_strings(data.get("modules")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Features:
    loyalty: bool | None = None
    inventory: bool | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Features:
        return cls(
            loyalty=_bool(data.get("loyalty")),
            inventory=_bool(data.get("inventory")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Whoami:
    restaurant: Restaurant | None = None
    key: ApiKeyInfo | None = None
    subscription: Subscription | None = None
    features: Features | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Whoami:
        return cls(
            restaurant=_object(data.get("restaurant"), Restaurant),
            key=_object(data.get("key"), ApiKeyInfo),
            subscription=_object(data.get("subscription"), Subscription),
            features=_object(data.get("features"), Features),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Category:
    name: str | None = None
    position: int | None = None
    products: int | None = None
    available: int | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Category:
        return cls(
            name=_str(data.get("name")),
            position=_int(data.get("position")),
            products=_int(data.get("products")),
            available=_int(data.get("available")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Modifier:
    id: str | None = None
    name: str | None = None
    price_delta: float | None = None
    position: int | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Modifier:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            price_delta=_float(data.get("priceDelta")),
            position=_int(data.get("position")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ModifierGroup:
    id: str | None = None
    name: str | None = None
    required: bool | None = None
    position: int | None = None
    modifiers: list[Modifier] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ModifierGroup:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            required=_bool(data.get("required")),
            position=_int(data.get("position")),
            modifiers=_list_of(data.get("modifiers"), Modifier),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ProductTranslation:
    name: str | None = None
    description: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ProductTranslation:
        return cls(
            name=_str(data.get("name")),
            description=_str(data.get("description")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Product:
    id: str | None = None
    name: str | None = None
    category: str | None = None
    description: str | None = None
    price: float | None = None
    available: bool | None = None
    popular: bool | None = None
    position: int | None = None
    prep_minutes: int | None = None
    station: str | None = None
    vat_rate: float | None = None
    vegetarian: bool | None = None
    spicy: bool | None = None
    allergens: list[str] = field(default_factory=list)
    discountable: bool | None = None
    has_modifiers: bool | None = None
    image: str | None = None
    video: str | None = None
    modifier_groups: list[ModifierGroup] = field(default_factory=list)
    translations: dict[str, ProductTranslation] = field(default_factory=dict)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Product:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            category=_str(data.get("category")),
            description=_str(data.get("description")),
            price=_float(data.get("price")),
            available=_bool(data.get("available")),
            popular=_bool(data.get("popular")),
            position=_int(data.get("position")),
            prep_minutes=_int(data.get("prepMinutes")),
            station=_str(data.get("station")),
            vat_rate=_float(data.get("vatRate")),
            vegetarian=_bool(data.get("vegetarian")),
            spicy=_bool(data.get("spicy")),
            allergens=_strings(data.get("allergens")),
            discountable=_bool(data.get("discountable")),
            has_modifiers=_bool(data.get("hasModifiers")),
            image=_str(data.get("image")),
            video=_str(data.get("video")),
            modifier_groups=_list_of(data.get("modifierGroups"), ModifierGroup),
            translations=_map_of(data.get("translations"), ProductTranslation),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class StopListItem:
    id: str | None = None
    name: str | None = None
    category: str | None = None
    price: float | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> StopListItem:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            category=_str(data.get("category")),
            price=_float(data.get("price")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ReservationGuest:
    name: str | None = None
    phone: str | None = None
    email: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ReservationGuest:
        return cls(
            name=_str(data.get("name")),
            phone=_str(data.get("phone")),
            email=_str(data.get("email")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ReservationTable:
    id: str | None = None
    label: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ReservationTable:
        return cls(
            id=_str(data.get("id")),
            label=_str(data.get("label")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ReservationPreOrderItem:
    product_id: str | None = None
    name: str | None = None
    price: float | None = None
    qty: int | None = None
    note: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ReservationPreOrderItem:
        return cls(
            product_id=_str(data.get("productId")),
            name=_str(data.get("name")),
            price=_float(data.get("price")),
            qty=_int(data.get("qty")),
            note=_str(data.get("note")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Reservation:
    id: str | None = None
    code: str | None = None
    status: str | None = None
    source: str | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    guests: int | None = None
    zone: str | None = None
    table: ReservationTable | None = None
    guest: ReservationGuest | None = None
    special_request: str | None = None
    allergy_note: str | None = None
    birthday: bool | None = None
    child_chair: bool | None = None
    deposit_paid: float | None = None
    pre_order: list[ReservationPreOrderItem] = field(default_factory=list)
    external_ref: str | None = None
    decided_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Reservation:
        return cls(
            id=_str(data.get("id")),
            code=_str(data.get("code")),
            status=_str(data.get("status")),
            source=_str(data.get("source")),
            starts_at=_datetime(data.get("startsAt")),
            ends_at=_datetime(data.get("endsAt")),
            guests=_int(data.get("guests")),
            zone=_str(data.get("zone")),
            table=_object(data.get("table"), ReservationTable),
            guest=_object(data.get("guest"), ReservationGuest),
            special_request=_str(data.get("specialRequest")),
            allergy_note=_str(data.get("allergyNote")),
            birthday=_bool(data.get("birthday")),
            child_chair=_bool(data.get("childChair")),
            deposit_paid=_float(data.get("depositPaid")),
            pre_order=_list_of(data.get("preOrder"), ReservationPreOrderItem),
            external_ref=_str(data.get("externalRef")),
            decided_at=_datetime(data.get("decidedAt")),
            created_at=_datetime(data.get("createdAt")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class AvailableTable:
    id: str | None = None
    label: str | None = None
    hall_id: str | None = None
    zone: str | None = None
    seats: int | None = None
    free: bool | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> AvailableTable:
        return cls(
            id=_str(data.get("id")),
            label=_str(data.get("label")),
            hall_id=_str(data.get("hallId")),
            zone=_str(data.get("zone")),
            seats=_int(data.get("seats")),
            free=_bool(data.get("free")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class TableAvailability:
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    duration_minutes: int | None = None
    open_time: str | None = None
    close_time: str | None = None
    tables: list[AvailableTable] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> TableAvailability:
        return cls(
            starts_at=_datetime(data.get("startsAt")),
            ends_at=_datetime(data.get("endsAt")),
            duration_minutes=_int(data.get("durationMinutes")),
            open_time=_str(data.get("openTime")),
            close_time=_str(data.get("closeTime")),
            tables=_list_of(data.get("tables"), AvailableTable),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class OrderItem:
    id: str | None = None
    product_id: str | None = None
    name: str | None = None
    qty: int | None = None
    price: float | None = None
    list_price: float | None = None
    modifiers: str | None = None
    note: str | None = None
    status: str | None = None
    comp: bool | None = None
    campaign: str | None = None
    cancel_reason: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> OrderItem:
        return cls(
            id=_str(data.get("id")),
            product_id=_str(data.get("productId")),
            name=_str(data.get("name")),
            qty=_int(data.get("qty")),
            price=_float(data.get("price")),
            list_price=_float(data.get("listPrice")),
            modifiers=_str(data.get("modifiers")),
            note=_str(data.get("note")),
            status=_str(data.get("status")),
            comp=_bool(data.get("comp")),
            campaign=_str(data.get("campaign")),
            cancel_reason=_str(data.get("cancelReason")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class DeliveryPlatform:
    id: str | None = None
    name: str | None = None
    ref: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> DeliveryPlatform:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            ref=_str(data.get("ref")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class OrderDelivery:
    status: str | None = None
    platform: DeliveryPlatform | None = None
    address: str | None = None
    customer_phone: str | None = None
    courier_name: str | None = None
    note: str | None = None
    payment_method: str | None = None
    fee: float | None = None
    platform_total: float | None = None
    accepted_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> OrderDelivery:
        return cls(
            status=_str(data.get("status")),
            platform=_object(data.get("platform"), DeliveryPlatform),
            address=_str(data.get("address")),
            customer_phone=_str(data.get("customerPhone")),
            courier_name=_str(data.get("courierName")),
            note=_str(data.get("note")),
            payment_method=_str(data.get("paymentMethod")),
            fee=_float(data.get("fee")),
            platform_total=_float(data.get("platformTotal")),
            accepted_at=_datetime(data.get("acceptedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Order:
    id: str | None = None
    number: str | None = None
    daily_number: int | None = None
    kind: str | None = None
    order_type: str | None = None
    status: str | None = None
    table_id: str | None = None
    bill_id: str | None = None
    customer_name: str | None = None
    allergy_note: str | None = None
    items: list[OrderItem] = field(default_factory=list)
    subtotal: float | None = None
    delivery: OrderDelivery | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Order:
        return cls(
            id=_str(data.get("id")),
            number=_str(data.get("number")),
            daily_number=_int(data.get("dailyNumber")),
            kind=_str(data.get("kind")),
            order_type=_str(data.get("orderType")),
            status=_str(data.get("status")),
            table_id=_str(data.get("tableId")),
            bill_id=_str(data.get("billId")),
            customer_name=_str(data.get("customerName")),
            allergy_note=_str(data.get("allergyNote")),
            items=_list_of(data.get("items"), OrderItem),
            subtotal=_float(data.get("subtotal")),
            delivery=_object(data.get("delivery"), OrderDelivery),
            created_at=_datetime(data.get("createdAt")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Bill:
    id: str | None = None
    table_id: str | None = None
    status: str | None = None
    guests: int | None = None
    waiter: str | None = None
    customer_id: str | None = None
    reservation_id: str | None = None
    order_ids: list[str] = field(default_factory=list)
    subtotal: float | None = None
    discount_percent: float | None = None
    bill_discount: float | None = None
    service_fee_percent: float | None = None
    service_fee: float | None = None
    total: float | None = None
    paid: float | None = None
    remaining: float | None = None
    opened_at: datetime | None = None
    closed_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Bill:
        return cls(
            id=_str(data.get("id")),
            table_id=_str(data.get("tableId")),
            status=_str(data.get("status")),
            guests=_int(data.get("guests")),
            waiter=_str(data.get("waiter")),
            customer_id=_str(data.get("customerId")),
            reservation_id=_str(data.get("reservationId")),
            order_ids=_strings(data.get("orderIds")),
            subtotal=_float(data.get("subtotal")),
            discount_percent=_float(data.get("discountPercent")),
            bill_discount=_float(data.get("billDiscount")),
            service_fee_percent=_float(data.get("serviceFeePercent")),
            service_fee=_float(data.get("serviceFee")),
            total=_float(data.get("total")),
            paid=_float(data.get("paid")),
            remaining=_float(data.get("remaining")),
            opened_at=_datetime(data.get("openedAt")),
            closed_at=_datetime(data.get("closedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class PaymentCard:
    masked_pan: str | None = None
    scheme: str | None = None
    bank: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> PaymentCard:
        return cls(
            masked_pan=_str(data.get("maskedPan")),
            scheme=_str(data.get("scheme")),
            bank=_str(data.get("bank")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class PaymentPlatform:
    id: str | None = None
    name: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> PaymentPlatform:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Payment:
    id: str | None = None
    status: str | None = None
    method: str | None = None
    recorded_method: str | None = None
    amount: float | None = None
    tip: float | None = None
    refunded_amount: float | None = None
    refunded_at: datetime | None = None
    refund_reason: str | None = None
    bill_id: str | None = None
    reservation_id: str | None = None
    order_id: str | None = None
    taken_at: str | None = None
    card: PaymentCard | None = None
    platform: PaymentPlatform | None = None
    created_at: datetime | None = None
    settled_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Payment:
        return cls(
            id=_str(data.get("id")),
            status=_str(data.get("status")),
            method=_str(data.get("method")),
            recorded_method=_str(data.get("recordedMethod")),
            amount=_float(data.get("amount")),
            tip=_float(data.get("tip")),
            refunded_amount=_float(data.get("refundedAmount")),
            refunded_at=_datetime(data.get("refundedAt")),
            refund_reason=_str(data.get("refundReason")),
            bill_id=_str(data.get("billId")),
            reservation_id=_str(data.get("reservationId")),
            order_id=_str(data.get("orderId")),
            taken_at=_str(data.get("takenAt")),
            card=_object(data.get("card"), PaymentCard),
            platform=_object(data.get("platform"), PaymentPlatform),
            created_at=_datetime(data.get("createdAt")),
            settled_at=_datetime(data.get("settledAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Hall:
    id: str | None = None
    name: str | None = None
    position: int | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Hall:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            position=_int(data.get("position")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Table:
    id: str | None = None
    label: str | None = None
    hall_id: str | None = None
    zone: str | None = None
    seats: int | None = None
    shape: str | None = None
    status: str | None = None
    guests: int | None = None
    waiter: str | None = None
    seated_since: str | None = None
    open_orders: int | None = None
    bill_id: str | None = None
    bill_total: float | None = None
    bill_requested: bool | None = None
    bill_settled: bool | None = None
    merged_into: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Table:
        return cls(
            id=_str(data.get("id")),
            label=_str(data.get("label")),
            hall_id=_str(data.get("hallId")),
            zone=_str(data.get("zone")),
            seats=_int(data.get("seats")),
            shape=_str(data.get("shape")),
            status=_str(data.get("status")),
            guests=_int(data.get("guests")),
            waiter=_str(data.get("waiter")),
            seated_since=_str(data.get("seatedSince")),
            open_orders=_int(data.get("openOrders")),
            bill_id=_str(data.get("billId")),
            bill_total=_float(data.get("billTotal")),
            bill_requested=_bool(data.get("billRequested")),
            bill_settled=_bool(data.get("billSettled")),
            merged_into=_str(data.get("mergedInto")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Customer:
    id: str | None = None
    name: str | None = None
    phone: str | None = None
    note: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Customer:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            phone=_str(data.get("phone")),
            note=_str(data.get("note")),
            created_at=_datetime(data.get("createdAt")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class LoyaltyProgram:
    stamps_needed: int | None = None
    earn_by: str | None = None
    min_bill: float | None = None
    once_per_day: bool | None = None
    reward_name: str | None = None
    reward_scope: str | None = None
    reward_categories: list[str] = field(default_factory=list)
    reward_product_ids: list[str] = field(default_factory=list)
    reward_max_price: float | None = None
    terms: str | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> LoyaltyProgram:
        return cls(
            stamps_needed=_int(data.get("stampsNeeded")),
            earn_by=_str(data.get("earnBy")),
            min_bill=_float(data.get("minBill")),
            once_per_day=_bool(data.get("oncePerDay")),
            reward_name=_str(data.get("rewardName")),
            reward_scope=_str(data.get("rewardScope")),
            reward_categories=_strings(data.get("rewardCategories")),
            reward_product_ids=_strings(data.get("rewardProductIds")),
            reward_max_price=_float(data.get("rewardMaxPrice")),
            terms=_str(data.get("terms")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class LoyaltyCard:
    id: str | None = None
    name: str | None = None
    phone: str | None = None
    stamps: int | None = None
    total_stamps: int | None = None
    redeemed: int | None = None
    source: str | None = None
    last_visit_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> LoyaltyCard:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            phone=_str(data.get("phone")),
            stamps=_int(data.get("stamps")),
            total_stamps=_int(data.get("totalStamps")),
            redeemed=_int(data.get("redeemed")),
            source=_str(data.get("source")),
            last_visit_at=_datetime(data.get("lastVisitAt")),
            created_at=_datetime(data.get("createdAt")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Ingredient:
    id: str | None = None
    name: str | None = None
    unit: str | None = None
    stock: float | None = None
    on_open_bills: float | None = None
    available: float | None = None
    state: str | None = None
    low_stock: float | None = None
    par_stock: float | None = None
    cost_per_unit: float | None = None
    value: float | None = None
    prepared: bool | None = None
    by_store: dict[str, float] = field(default_factory=dict)
    updated_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Ingredient:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            unit=_str(data.get("unit")),
            stock=_float(data.get("stock")),
            on_open_bills=_float(data.get("onOpenBills")),
            available=_float(data.get("available")),
            state=_str(data.get("state")),
            low_stock=_float(data.get("lowStock")),
            par_stock=_float(data.get("parStock")),
            cost_per_unit=_float(data.get("costPerUnit")),
            value=_float(data.get("value")),
            prepared=_bool(data.get("prepared")),
            by_store=_floats(data.get("byStore")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class StockStore:
    id: str | None = None
    name: str | None = None
    is_default: bool | None = None
    stations: list[str] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> StockStore:
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            is_default=_bool(data.get("isDefault")),
            stations=_strings(data.get("stations")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class StockMove:
    id: str | None = None
    ingredient_id: str | None = None
    qty: float | None = None
    reason: str | None = None
    order_id: str | None = None
    invoice_id: str | None = None
    store_id: str | None = None
    note: str | None = None
    created_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> StockMove:
        return cls(
            id=_str(data.get("id")),
            ingredient_id=_str(data.get("ingredientId")),
            qty=_float(data.get("qty")),
            reason=_str(data.get("reason")),
            order_id=_str(data.get("orderId")),
            invoice_id=_str(data.get("invoiceId")),
            store_id=_str(data.get("storeId")),
            note=_str(data.get("note")),
            created_at=_datetime(data.get("createdAt")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class ReviewRatings:
    food: float | None = None
    service: float | None = None
    atmosphere: float | None = None
    cleanliness: float | None = None
    price: float | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ReviewRatings:
        return cls(
            food=_float(data.get("food")),
            service=_float(data.get("service")),
            atmosphere=_float(data.get("atmosphere")),
            cleanliness=_float(data.get("cleanliness")),
            price=_float(data.get("price")),
            raw=dict(data),
        )


@dataclass(frozen=True, slots=True, kw_only=True)
class Review:
    id: str | None = None
    author: str | None = None
    overall: float | None = None
    ratings: ReviewRatings | None = None
    body: str | None = None
    visit_type: str | None = None
    visited_on: datetime | None = None
    verified: bool | None = None
    reply: str | None = None
    replied_at: datetime | None = None
    created_at: datetime | None = None
    raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> Review:
        return cls(
            id=_str(data.get("id")),
            author=_str(data.get("author")),
            overall=_float(data.get("overall")),
            ratings=_object(data.get("ratings"), ReviewRatings),
            body=_str(data.get("body")),
            visit_type=_str(data.get("visitType")),
            visited_on=_datetime(data.get("visitedOn")),
            verified=_bool(data.get("verified")),
            reply=_str(data.get("reply")),
            replied_at=_datetime(data.get("repliedAt")),
            created_at=_datetime(data.get("createdAt")),
            raw=dict(data),
        )
