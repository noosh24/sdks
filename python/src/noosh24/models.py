from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Mapping, Optional

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


@dataclass(frozen=True)
class Restaurant:
    id: Optional[str] = None
    name: Optional[str] = None
    slug: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Restaurant":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            slug=_str(data.get("slug")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ApiKeyInfo:
    id: Optional[str] = None
    name: Optional[str] = None
    prefix: Optional[str] = None
    scopes: List[str] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ApiKeyInfo":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            prefix=_str(data.get("prefix")),
            scopes=_strings(data.get("scopes")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Subscription:
    status: Optional[str] = None
    modules: List[str] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Subscription":
        return cls(
            status=_str(data.get("status")),
            modules=_strings(data.get("modules")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Features:
    loyalty: Optional[bool] = None
    inventory: Optional[bool] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Features":
        return cls(
            loyalty=_bool(data.get("loyalty")),
            inventory=_bool(data.get("inventory")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Whoami:
    restaurant: Optional[Restaurant] = None
    key: Optional[ApiKeyInfo] = None
    subscription: Optional[Subscription] = None
    features: Optional[Features] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Whoami":
        return cls(
            restaurant=_object(data.get("restaurant"), Restaurant),
            key=_object(data.get("key"), ApiKeyInfo),
            subscription=_object(data.get("subscription"), Subscription),
            features=_object(data.get("features"), Features),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Category:
    name: Optional[str] = None
    position: Optional[int] = None
    products: Optional[int] = None
    available: Optional[int] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Category":
        return cls(
            name=_str(data.get("name")),
            position=_int(data.get("position")),
            products=_int(data.get("products")),
            available=_int(data.get("available")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Modifier:
    id: Optional[str] = None
    name: Optional[str] = None
    price_delta: Optional[float] = None
    position: Optional[int] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Modifier":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            price_delta=_float(data.get("priceDelta")),
            position=_int(data.get("position")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ModifierGroup:
    id: Optional[str] = None
    name: Optional[str] = None
    required: Optional[bool] = None
    position: Optional[int] = None
    modifiers: List[Modifier] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ModifierGroup":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            required=_bool(data.get("required")),
            position=_int(data.get("position")),
            modifiers=_list_of(data.get("modifiers"), Modifier),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ProductTranslation:
    name: Optional[str] = None
    description: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ProductTranslation":
        return cls(
            name=_str(data.get("name")),
            description=_str(data.get("description")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Product:
    id: Optional[str] = None
    name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    available: Optional[bool] = None
    popular: Optional[bool] = None
    position: Optional[int] = None
    prep_minutes: Optional[int] = None
    station: Optional[str] = None
    vat_rate: Optional[float] = None
    vegetarian: Optional[bool] = None
    spicy: Optional[bool] = None
    allergens: List[str] = field(default_factory=list)
    discountable: Optional[bool] = None
    has_modifiers: Optional[bool] = None
    image: Optional[str] = None
    video: Optional[str] = None
    modifier_groups: List[ModifierGroup] = field(default_factory=list)
    translations: Dict[str, ProductTranslation] = field(default_factory=dict)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Product":
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


@dataclass(frozen=True)
class StopListItem:
    id: Optional[str] = None
    name: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "StopListItem":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            category=_str(data.get("category")),
            price=_float(data.get("price")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ReservationGuest:
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ReservationGuest":
        return cls(
            name=_str(data.get("name")),
            phone=_str(data.get("phone")),
            email=_str(data.get("email")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ReservationTable:
    id: Optional[str] = None
    label: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ReservationTable":
        return cls(
            id=_str(data.get("id")),
            label=_str(data.get("label")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class ReservationPreOrderItem:
    product_id: Optional[str] = None
    name: Optional[str] = None
    price: Optional[float] = None
    qty: Optional[int] = None
    note: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ReservationPreOrderItem":
        return cls(
            product_id=_str(data.get("productId")),
            name=_str(data.get("name")),
            price=_float(data.get("price")),
            qty=_int(data.get("qty")),
            note=_str(data.get("note")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Reservation:
    id: Optional[str] = None
    code: Optional[str] = None
    status: Optional[str] = None
    source: Optional[str] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    guests: Optional[int] = None
    zone: Optional[str] = None
    table: Optional[ReservationTable] = None
    guest: Optional[ReservationGuest] = None
    special_request: Optional[str] = None
    allergy_note: Optional[str] = None
    birthday: Optional[bool] = None
    child_chair: Optional[bool] = None
    deposit_paid: Optional[float] = None
    pre_order: List[ReservationPreOrderItem] = field(default_factory=list)
    external_ref: Optional[str] = None
    decided_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Reservation":
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


@dataclass(frozen=True)
class AvailableTable:
    id: Optional[str] = None
    label: Optional[str] = None
    hall_id: Optional[str] = None
    zone: Optional[str] = None
    seats: Optional[int] = None
    free: Optional[bool] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "AvailableTable":
        return cls(
            id=_str(data.get("id")),
            label=_str(data.get("label")),
            hall_id=_str(data.get("hallId")),
            zone=_str(data.get("zone")),
            seats=_int(data.get("seats")),
            free=_bool(data.get("free")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class TableAvailability:
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    open_time: Optional[str] = None
    close_time: Optional[str] = None
    tables: List[AvailableTable] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "TableAvailability":
        return cls(
            starts_at=_datetime(data.get("startsAt")),
            ends_at=_datetime(data.get("endsAt")),
            duration_minutes=_int(data.get("durationMinutes")),
            open_time=_str(data.get("openTime")),
            close_time=_str(data.get("closeTime")),
            tables=_list_of(data.get("tables"), AvailableTable),
            raw=dict(data),
        )


@dataclass(frozen=True)
class OrderItem:
    id: Optional[str] = None
    product_id: Optional[str] = None
    name: Optional[str] = None
    qty: Optional[int] = None
    price: Optional[float] = None
    list_price: Optional[float] = None
    modifiers: Optional[str] = None
    note: Optional[str] = None
    status: Optional[str] = None
    comp: Optional[bool] = None
    campaign: Optional[str] = None
    cancel_reason: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "OrderItem":
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


@dataclass(frozen=True)
class DeliveryPlatform:
    id: Optional[str] = None
    name: Optional[str] = None
    ref: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "DeliveryPlatform":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            ref=_str(data.get("ref")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class OrderDelivery:
    status: Optional[str] = None
    platform: Optional[DeliveryPlatform] = None
    address: Optional[str] = None
    customer_phone: Optional[str] = None
    courier_name: Optional[str] = None
    note: Optional[str] = None
    payment_method: Optional[str] = None
    fee: Optional[float] = None
    platform_total: Optional[float] = None
    accepted_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "OrderDelivery":
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


@dataclass(frozen=True)
class Order:
    id: Optional[str] = None
    number: Optional[str] = None
    daily_number: Optional[int] = None
    kind: Optional[str] = None
    order_type: Optional[str] = None
    status: Optional[str] = None
    table_id: Optional[str] = None
    bill_id: Optional[str] = None
    customer_name: Optional[str] = None
    allergy_note: Optional[str] = None
    items: List[OrderItem] = field(default_factory=list)
    subtotal: Optional[float] = None
    delivery: Optional[OrderDelivery] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Order":
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


@dataclass(frozen=True)
class Bill:
    id: Optional[str] = None
    table_id: Optional[str] = None
    status: Optional[str] = None
    guests: Optional[int] = None
    waiter: Optional[str] = None
    customer_id: Optional[str] = None
    reservation_id: Optional[str] = None
    order_ids: List[str] = field(default_factory=list)
    subtotal: Optional[float] = None
    discount_percent: Optional[float] = None
    bill_discount: Optional[float] = None
    service_fee_percent: Optional[float] = None
    service_fee: Optional[float] = None
    total: Optional[float] = None
    paid: Optional[float] = None
    remaining: Optional[float] = None
    opened_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Bill":
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


@dataclass(frozen=True)
class PaymentCard:
    masked_pan: Optional[str] = None
    scheme: Optional[str] = None
    bank: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "PaymentCard":
        return cls(
            masked_pan=_str(data.get("maskedPan")),
            scheme=_str(data.get("scheme")),
            bank=_str(data.get("bank")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class PaymentPlatform:
    id: Optional[str] = None
    name: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "PaymentPlatform":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Payment:
    id: Optional[str] = None
    status: Optional[str] = None
    method: Optional[str] = None
    recorded_method: Optional[str] = None
    amount: Optional[float] = None
    tip: Optional[float] = None
    refunded_amount: Optional[float] = None
    refunded_at: Optional[datetime] = None
    refund_reason: Optional[str] = None
    bill_id: Optional[str] = None
    reservation_id: Optional[str] = None
    order_id: Optional[str] = None
    taken_at: Optional[str] = None
    card: Optional[PaymentCard] = None
    platform: Optional[PaymentPlatform] = None
    created_at: Optional[datetime] = None
    settled_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Payment":
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


@dataclass(frozen=True)
class Hall:
    id: Optional[str] = None
    name: Optional[str] = None
    position: Optional[int] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Hall":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            position=_int(data.get("position")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Table:
    id: Optional[str] = None
    label: Optional[str] = None
    hall_id: Optional[str] = None
    zone: Optional[str] = None
    seats: Optional[int] = None
    shape: Optional[str] = None
    status: Optional[str] = None
    guests: Optional[int] = None
    waiter: Optional[str] = None
    seated_since: Optional[str] = None
    open_orders: Optional[int] = None
    bill_id: Optional[str] = None
    bill_total: Optional[float] = None
    bill_requested: Optional[bool] = None
    bill_settled: Optional[bool] = None
    merged_into: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Table":
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


@dataclass(frozen=True)
class Customer:
    id: Optional[str] = None
    name: Optional[str] = None
    phone: Optional[str] = None
    note: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Customer":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            phone=_str(data.get("phone")),
            note=_str(data.get("note")),
            created_at=_datetime(data.get("createdAt")),
            updated_at=_datetime(data.get("updatedAt")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class LoyaltyProgram:
    stamps_needed: Optional[int] = None
    earn_by: Optional[str] = None
    min_bill: Optional[float] = None
    once_per_day: Optional[bool] = None
    reward_name: Optional[str] = None
    reward_scope: Optional[str] = None
    reward_categories: List[str] = field(default_factory=list)
    reward_product_ids: List[str] = field(default_factory=list)
    reward_max_price: Optional[float] = None
    terms: Optional[str] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "LoyaltyProgram":
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


@dataclass(frozen=True)
class LoyaltyCard:
    id: Optional[str] = None
    name: Optional[str] = None
    phone: Optional[str] = None
    stamps: Optional[int] = None
    total_stamps: Optional[int] = None
    redeemed: Optional[int] = None
    source: Optional[str] = None
    last_visit_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "LoyaltyCard":
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


@dataclass(frozen=True)
class Ingredient:
    id: Optional[str] = None
    name: Optional[str] = None
    unit: Optional[str] = None
    stock: Optional[float] = None
    on_open_bills: Optional[float] = None
    available: Optional[float] = None
    state: Optional[str] = None
    low_stock: Optional[float] = None
    par_stock: Optional[float] = None
    cost_per_unit: Optional[float] = None
    value: Optional[float] = None
    prepared: Optional[bool] = None
    by_store: Dict[str, float] = field(default_factory=dict)
    updated_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Ingredient":
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


@dataclass(frozen=True)
class StockStore:
    id: Optional[str] = None
    name: Optional[str] = None
    is_default: Optional[bool] = None
    stations: List[str] = field(default_factory=list)
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "StockStore":
        return cls(
            id=_str(data.get("id")),
            name=_str(data.get("name")),
            is_default=_bool(data.get("isDefault")),
            stations=_strings(data.get("stations")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class StockMove:
    id: Optional[str] = None
    ingredient_id: Optional[str] = None
    qty: Optional[float] = None
    reason: Optional[str] = None
    order_id: Optional[str] = None
    invoice_id: Optional[str] = None
    store_id: Optional[str] = None
    note: Optional[str] = None
    created_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "StockMove":
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


@dataclass(frozen=True)
class ReviewRatings:
    food: Optional[float] = None
    service: Optional[float] = None
    atmosphere: Optional[float] = None
    cleanliness: Optional[float] = None
    price: Optional[float] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ReviewRatings":
        return cls(
            food=_float(data.get("food")),
            service=_float(data.get("service")),
            atmosphere=_float(data.get("atmosphere")),
            cleanliness=_float(data.get("cleanliness")),
            price=_float(data.get("price")),
            raw=dict(data),
        )


@dataclass(frozen=True)
class Review:
    id: Optional[str] = None
    author: Optional[str] = None
    overall: Optional[float] = None
    ratings: Optional[ReviewRatings] = None
    body: Optional[str] = None
    visit_type: Optional[str] = None
    visited_on: Optional[datetime] = None
    verified: Optional[bool] = None
    reply: Optional[str] = None
    replied_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Review":
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
