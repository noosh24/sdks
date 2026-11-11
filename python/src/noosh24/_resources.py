from __future__ import annotations

from dataclasses import dataclass
from datetime import date as Date
from typing import TYPE_CHECKING, Any, Callable, Dict, Iterator, List, Mapping, Optional, Sequence, TypeVar, Union
from urllib.parse import quote

from ._convert import build
from .models import (
    Bill,
    Category,
    Customer,
    Hall,
    Ingredient,
    LoyaltyCard,
    LoyaltyProgram,
    Order,
    Payment,
    Product,
    Reservation,
    Review,
    StockMove,
    StockStore,
    StopListItem,
    Table,
    TableAvailability,
)
from .pagination import Page
from .where import Where

if TYPE_CHECKING:
    from ._client import Noosh24

__all__ = [
    "CreateReservationResult",
    "PreOrderLine",
    "Menu",
    "Reservations",
    "Orders",
    "Payments",
    "Tables",
    "Customers",
    "Loyalty",
    "Stock",
    "Reviews",
]

T = TypeVar("T")
Sort = Union[str, Sequence[str], None]
WhereArg = Union[str, Where, None]
Expand = Union[str, Sequence[str], None]
DateArg = Union[str, Date]


@dataclass(frozen=True)
class PreOrderLine:
    item_id: str
    qty: int
    note: Optional[str] = None


@dataclass(frozen=True)
class CreateReservationResult:
    reservation: Reservation
    created: bool


def _id(value: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("An id is required")
    return quote(value, safe="")


def _list(value: Union[str, Sequence[str], None]) -> List[str]:
    if value is None or value == "":
        return []
    if isinstance(value, str):
        return [value]
    return list(value)


def _date(value: DateArg) -> str:
    return value.isoformat() if isinstance(value, Date) else value


def _list_query(limit: Optional[int], offset: Optional[int], sort: Sort, where: WhereArg, expand: Expand = None) -> Dict[str, Any]:
    query: Dict[str, Any] = {}
    if limit is not None:
        query["limit"] = int(limit)
    if offset is not None:
        query["offset"] = int(offset)
    sorts = _list(sort)
    if sorts:
        query["sort"] = sorts
    if where is not None:
        text = str(where)
        if text:
            query["where"] = text
    expands = _list(expand)
    if expands:
        query["expand"] = expands
    return query


class _Resource:
    def __init__(self, client: "Noosh24") -> None:
        self._client = client

    def _page(self, path: str, factory: Callable[[Mapping[str, Any]], T], query: Dict[str, Any]) -> Page[T]:
        _, data = self._client.request("GET", path, query=query)
        data = data if isinstance(data, Mapping) else {}
        items = [factory(item) for item in data.get("items") or [] if isinstance(item, Mapping)]
        return Page(
            items=items,
            total=int(data.get("total", len(items))),
            limit=int(data.get("limit", query.get("limit", len(items)))),
            offset=int(data.get("offset", query.get("offset", 0))),
        )

    def _paginate(self, path: str, factory: Callable[[Mapping[str, Any]], T], query: Dict[str, Any], page_size: int) -> Iterator[T]:
        query = dict(query)
        query.setdefault("limit", page_size)
        query.setdefault("offset", 0)
        while True:
            page = self._page(path, factory, query)
            for item in page.items:
                yield item
            if not page.has_more:
                return
            query["offset"] = page.next_offset

    def _all(self, path: str, factory: Callable[[Mapping[str, Any]], T]) -> List[T]:
        _, data = self._client.request("GET", path)
        data = data if isinstance(data, Mapping) else {}
        return [factory(item) for item in data.get("items") or [] if isinstance(item, Mapping)]

    def _one(self, path: str, factory: Callable[[Mapping[str, Any]], T], query: Optional[Dict[str, Any]] = None) -> T:
        _, data = self._client.request("GET", path, query=query)
        return build(factory, data)


class Menu(_Resource):
    def list_categories(self) -> List[Category]:
        return self._all("/menu/categories", Category.from_dict)

    def list_products(
        self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None, expand: Expand = None
    ) -> Page[Product]:
        return self._page("/menu/products", Product.from_dict, _list_query(limit, offset, sort, where, expand))

    def iterate_products(
        self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None, expand: Expand = None
    ) -> Iterator[Product]:
        page_size = 50 if _list(expand) else 100
        return self._paginate("/menu/products", Product.from_dict, _list_query(limit, offset, sort, where, expand), page_size)

    def get_product(self, product_id: str, *, expand: Expand = None) -> Product:
        expands = _list(expand)
        return self._one("/menu/products/" + _id(product_id), Product.from_dict, {"expand": expands} if expands else None)

    def get_stop_list(self) -> List[StopListItem]:
        return self._all("/menu/stop-list", StopListItem.from_dict)


class Reservations(_Resource):
    def list(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Reservation]:
        return self._page("/reservations", Reservation.from_dict, _list_query(limit, offset, sort, where))

    def iterate(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Reservation]:
        return self._paginate("/reservations", Reservation.from_dict, _list_query(limit, offset, sort, where), 100)

    def get(self, reservation_id: str) -> Reservation:
        return self._one("/reservations/" + _id(reservation_id), Reservation.from_dict)

    def availability(self, date: DateArg, time: str, guests: Optional[int] = None) -> TableAvailability:
        return self._one(
            "/reservations/availability", TableAvailability.from_dict, {"date": _date(date), "time": time, "guests": guests}
        )

    def create(
        self,
        *,
        date: DateArg,
        time: str,
        guests: int,
        guest_name: str,
        phone: str,
        email: Optional[str] = None,
        table_id: Optional[str] = None,
        zone: Optional[str] = None,
        special_request: Optional[str] = None,
        allergy_note: Optional[str] = None,
        birthday: Optional[bool] = None,
        child_chair: Optional[bool] = None,
        pre_order: Optional[Sequence[Union[PreOrderLine, Mapping[str, Any]]]] = None,
        external_ref: Optional[str] = None,
    ) -> CreateReservationResult:
        body: Dict[str, Any] = {
            "date": _date(date),
            "time": time,
            "guests": guests,
            "guestName": guest_name,
            "phone": phone,
        }
        optional = {
            "email": email,
            "tableId": table_id,
            "zone": zone,
            "specialRequest": special_request,
            "allergyNote": allergy_note,
            "birthday": birthday,
            "childChair": child_chair,
            "externalRef": external_ref,
        }
        body.update({k: v for k, v in optional.items() if v is not None})
        if pre_order is not None:
            body["preOrder"] = [_pre_order_line(line) for line in pre_order]
        idempotent = bool(external_ref and external_ref.strip())
        status, data = self._client.request("POST", "/reservations", body=body, retryable=idempotent)
        return CreateReservationResult(reservation=build(Reservation.from_dict, data), created=status == 201)

    def cancel(self, reservation_id: str) -> Reservation:
        _, data = self._client.request("POST", "/reservations/%s/cancel" % _id(reservation_id))
        return build(Reservation.from_dict, data)


def _pre_order_line(line: Union[PreOrderLine, Mapping[str, Any]]) -> Dict[str, Any]:
    if isinstance(line, PreOrderLine):
        out: Dict[str, Any] = {"itemId": line.item_id, "qty": line.qty}
        if line.note is not None:
            out["note"] = line.note
        return out
    out = {"itemId": line.get("item_id", line.get("itemId")), "qty": line["qty"]}
    if line.get("note") is not None:
        out["note"] = line["note"]
    return out


class Orders(_Resource):
    def list(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Order]:
        return self._page("/orders", Order.from_dict, _list_query(limit, offset, sort, where))

    def iterate(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Order]:
        return self._paginate("/orders", Order.from_dict, _list_query(limit, offset, sort, where), 100)

    def get(self, order_id: str) -> Order:
        return self._one("/orders/" + _id(order_id), Order.from_dict)

    def list_bills(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Bill]:
        return self._page("/bills", Bill.from_dict, _list_query(limit, offset, sort, where))

    def iterate_bills(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Bill]:
        return self._paginate("/bills", Bill.from_dict, _list_query(limit, offset, sort, where), 50)

    def get_bill(self, bill_id: str) -> Bill:
        return self._one("/bills/" + _id(bill_id), Bill.from_dict)


class Payments(_Resource):
    def list(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Payment]:
        return self._page("/payments", Payment.from_dict, _list_query(limit, offset, sort, where))

    def iterate(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Payment]:
        return self._paginate("/payments", Payment.from_dict, _list_query(limit, offset, sort, where), 100)

    def get(self, payment_id: str) -> Payment:
        return self._one("/payments/" + _id(payment_id), Payment.from_dict)

    def z_report(self, date: Optional[DateArg] = None) -> Dict[str, Any]:
        _, data = self._client.request("GET", "/reports/z", query={"date": _date(date)} if date is not None else None)
        return dict(data) if isinstance(data, Mapping) else {}


class Tables(_Resource):
    def list(self) -> List[Table]:
        return self._all("/tables", Table.from_dict)

    def list_halls(self) -> List[Hall]:
        return self._all("/halls", Hall.from_dict)


class Customers(_Resource):
    def list(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Customer]:
        return self._page("/customers", Customer.from_dict, _list_query(limit, offset, sort, where))

    def iterate(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Customer]:
        return self._paginate("/customers", Customer.from_dict, _list_query(limit, offset, sort, where), 100)

    def get(self, customer_id: str) -> Customer:
        return self._one("/customers/" + _id(customer_id), Customer.from_dict)


class Loyalty(_Resource):
    def get_program(self) -> LoyaltyProgram:
        return self._one("/loyalty/program", LoyaltyProgram.from_dict)

    def list_cards(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[LoyaltyCard]:
        return self._page("/loyalty/cards", LoyaltyCard.from_dict, _list_query(limit, offset, sort, where))

    def iterate_cards(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[LoyaltyCard]:
        return self._paginate("/loyalty/cards", LoyaltyCard.from_dict, _list_query(limit, offset, sort, where), 100)


class Stock(_Resource):
    def list_ingredients(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Ingredient]:
        return self._page("/stock/ingredients", Ingredient.from_dict, _list_query(limit, offset, sort, where))

    def iterate_ingredients(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Ingredient]:
        return self._paginate("/stock/ingredients", Ingredient.from_dict, _list_query(limit, offset, sort, where), 100)

    def list_moves(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[StockMove]:
        return self._page("/stock/moves", StockMove.from_dict, _list_query(limit, offset, sort, where))

    def iterate_moves(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[StockMove]:
        return self._paginate("/stock/moves", StockMove.from_dict, _list_query(limit, offset, sort, where), 100)

    def list_stores(self) -> List[StockStore]:
        return self._all("/stock/stores", StockStore.from_dict)


class Reviews(_Resource):
    def list(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Page[Review]:
        return self._page("/reviews", Review.from_dict, _list_query(limit, offset, sort, where))

    def iterate(self, *, limit: Optional[int] = None, offset: Optional[int] = None, sort: Sort = None, where: WhereArg = None) -> Iterator[Review]:
        return self._paginate("/reviews", Review.from_dict, _list_query(limit, offset, sort, where), 100)
