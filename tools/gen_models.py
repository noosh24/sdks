import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MODELS = [
    ("Restaurant", "The venue a key belongs to.", "id s, name s, slug s"),
    ("ApiKeyInfo", "The key making the request.", "id s, name s, prefix s, scopes [s]"),
    ("Subscription", "The venue's subscription.", "status s, modules [s]"),
    ("Features", "Modules some endpoints need.", "loyalty b, inventory b"),
    ("Whoami", "Which venue, scopes and modules a key gives you.", "restaurant Restaurant, key ApiKeyInfo, subscription Subscription, features Features"),
    ("Category", "A menu section.", "name s, position i, products i, available i"),
    ("Modifier", "One option of a modifier group.", "id s, name s, priceDelta f, position i"),
    ("ModifierGroup", "A group of options a product can take.", "id s, name s, required b, position i, modifiers [Modifier]"),
    ("ProductTranslation", "A product's name and description in one language.", "name s, description s"),
    ("Product", "A product on the venue's menu.", "id s, name s, category s, description s, price f, available b, popular b, position i, prepMinutes i, station s, vatRate f?, vegetarian b, spicy b, allergens [s], discountable b, hasModifiers b, image s?, video s?, modifierGroups [ModifierGroup]~, translations {ProductTranslation}~"),
    ("StopListItem", "A product that is off right now.", "id s, name s, category s, price f"),
    ("ReservationGuest", "The guest a booking is for.", "name s, phone s, email s?"),
    ("ReservationTable", "The table a booking holds.", "id s, label s"),
    ("ReservationPreOrderItem", "A dish ordered ahead with a booking.", "productId s?, name s, price f, qty i, note s?"),
    ("Reservation", "A booking at the venue.", "id s, code s, status s, source s, startsAt t, endsAt t, guests i, zone s, table ReservationTable?, guest ReservationGuest, specialRequest s?, allergyNote s?, birthday b, childChair b, depositPaid f, preOrder [ReservationPreOrderItem], externalRef s?, decidedAt t?, createdAt t, updatedAt t"),
    ("AvailableTable", "A table and whether it is free for the asked sitting.", "id s, label s, hallId s, zone s, seats i, free b"),
    ("TableAvailability", "Which tables are free for a sitting.", "startsAt t, endsAt t, durationMinutes i, openTime s, closeTime s, tables [AvailableTable]"),
    ("OrderItem", "One line of an order.", "id s, productId s?, name s, qty i, price f, listPrice f?, modifiers s?, note s?, status s, comp b, campaign s?, cancelReason s?"),
    ("DeliveryPlatform", "The delivery platform an order came from.", "id s?, name s?, ref s?"),
    ("OrderDelivery", "Delivery details of an order.", "status s?, platform DeliveryPlatform?, address s?, customerPhone s?, courierName s?, note s?, paymentMethod s?, fee f?, platformTotal f?, acceptedAt t?"),
    ("Order", "A table, counter or delivery order.", "id s, number s, dailyNumber i?, kind s, orderType s?, status s, tableId s, billId s, customerName s?, allergyNote s?, items [OrderItem], subtotal f, delivery OrderDelivery?, createdAt t, updatedAt t"),
    ("Bill", "A table bill (sitting) with its totals.", "id s, tableId s, status s, guests i, waiter s?, customerId s?, reservationId s?, orderIds [s], subtotal f, discountPercent f, billDiscount f, serviceFeePercent f, serviceFee f, total f, paid f, remaining f, openedAt t, closedAt t?"),
    ("PaymentCard", "The card a payment was made with.", "maskedPan s, scheme s, bank s"),
    ("PaymentPlatform", "The delivery platform that took a payment.", "id s, name s?"),
    ("Payment", "A payment or refund.", "id s, status s, method s, recordedMethod s, amount f, tip f, refundedAmount f?, refundedAt t?, refundReason s?, billId s?, reservationId s?, orderId s?, takenAt s, card PaymentCard?, platform PaymentPlatform?, createdAt t, settledAt t?"),
    ("Hall", "A room of the venue.", "id s, name s, position i"),
    ("Table", "A table with its live state.", "id s, label s, hallId s, zone s, seats i, shape s, status s, guests i?, waiter s?, seatedSince s?, openOrders i, billId s?, billTotal f?, billRequested b, billSettled b, mergedInto s?"),
    ("Customer", "A customer record of the venue.", "id s, name s, phone s, note s, createdAt t, updatedAt t"),
    ("LoyaltyProgram", "How stamps are earned and redeemed.", "stampsNeeded i, earnBy s, minBill f, oncePerDay b, rewardName s, rewardScope s, rewardCategories [s], rewardProductIds [s], rewardMaxPrice f, terms s"),
    ("LoyaltyCard", "A member's stamp card.", "id s, name s, phone s, stamps i, totalStamps i, redeemed i, source s, lastVisitAt t?, createdAt t, updatedAt t"),
    ("Ingredient", "An ingredient and its stock level.", "id s, name s, unit s, stock f, onOpenBills f, available f, state s, lowStock f, parStock f, costPerUnit f, value f, prepared b, byStore {f}, updatedAt t"),
    ("StockStore", "A stock room.", "id s, name s, isDefault b, stations [s]"),
    ("StockMove", "A movement of stock in or out.", "id s, ingredientId s, qty f, reason s, orderId s?, invoiceId s?, storeId s?, note s?, createdAt t"),
    ("ReviewRatings", "A review's per-topic ratings.", "food f, service f, atmosphere f, cleanliness f, price f"),
    ("Review", "A guest review and the venue's reply.", "id s, author s, overall f, ratings ReviewRatings, body s, visitType s, visitedOn t, verified b, reply s?, repliedAt t?, createdAt t"),
]

ENUMS = {
    ("Reservation", "status"): ["pending", "confirmed", "arriving", "checked_in", "completed", "cancelled", "no_show"],
    ("Reservation", "source"): ["noosh24", "open_api"],
    ("Order", "kind"): ["table", "counter", "delivery"],
    ("Order", "status"): ["pending_waiter", "new", "accepted", "preparing", "ready", "served", "cancelled"],
    ("OrderItem", "status"): ["new", "preparing", "ready", "cancelled"],
    ("Bill", "status"): ["open", "bill_requested", "paid", "closed", "abandoned", "merged"],
    ("Payment", "status"): ["pending", "requires_action", "succeeded", "failed", "refunded"],
    ("Payment", "method"): ["card", "apple_pay", "google_pay", "azqr", "cash", "birbank", "platform"],
    ("Payment", "takenAt"): ["till", "guest"],
    ("Table", "status"): ["available", "reserved", "occupied", "cleaning", "payment"],
    ("LoyaltyProgram", "earnBy"): ["visit", "items"],
    ("LoyaltyProgram", "rewardScope"): ["all", "categories", "items"],
    ("LoyaltyCard", "source"): ["panel", "till", "web", "app"],
    ("Ingredient", "state"): ["ok", "low", "empty"],
    ("Subscription", "status"): ["none", "trial", "active", "expiring", "grace", "restricted", "suspended"],
}


def parse(spec):
    out = []
    for part in spec.split(","):
        name, kind = part.strip().split(" ")
        optional = kind.endswith("~")
        kind = kind.rstrip("~")
        nullable = kind.endswith("?")
        kind = kind.rstrip("?")
        out.append((name, kind, nullable, optional))
    return out


def snake(name):
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def write(path, text):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(text)


def php_type(kind):
    if kind == "s":
        return "?string"
    if kind == "i":
        return "?int"
    if kind == "f":
        return "?float"
    if kind == "b":
        return "?bool"
    if kind == "t":
        return "?\\DateTimeImmutable"
    if kind.startswith("[") or kind.startswith("{"):
        return "?array"
    return "?" + kind


def php_doc(kind):
    if kind == "[s]":
        return "list<string>"
    if kind.startswith("["):
        return "list<" + kind[1:-1] + ">"
    if kind == "{f}":
        return "array<string, float>"
    if kind.startswith("{"):
        return "array<string, " + kind[1:-1] + ">"
    return None


def php_read(name, kind):
    key = "'" + name + "'"
    if kind == "s":
        return "self::string($data, %s)" % key
    if kind == "i":
        return "self::int($data, %s)" % key
    if kind == "f":
        return "self::float($data, %s)" % key
    if kind == "b":
        return "self::bool($data, %s)" % key
    if kind == "t":
        return "self::dateTime($data, %s)" % key
    if kind == "[s]":
        return "self::strings($data, %s)" % key
    if kind == "{f}":
        return "self::floats($data, %s)" % key
    if kind.startswith("["):
        return "self::listOf($data, %s, [%s::class, 'fromArray'])" % (key, kind[1:-1])
    if kind.startswith("{"):
        return "self::mapOf($data, %s, [%s::class, 'fromArray'])" % (key, kind[1:-1])
    return "self::object($data, %s, [%s::class, 'fromArray'])" % (key, kind)


def gen_php():
    for name, desc, spec in MODELS:
        fields = parse(spec)
        lines = [
            "<?php",
            "",
            "declare(strict_types=1);",
            "",
            "namespace Noosh24\\OpenApi\\Model;",
            "",
            "final class %s extends Model" % name,
            "{",
        ]
        for fname, kind, _, _ in fields:
            doc = php_doc(kind)
            if doc:
                lines.append("    /** @var %s|null */" % doc)
            lines.append("    public %s $%s = null;" % (php_type(kind), fname))
        lines += [
            "",
            "    /**",
            "     * @param array<string, mixed> $data",
            "     */",
            "    public static function fromArray(array $data): self",
            "    {",
            "        $model = new self($data);",
        ]
        for fname, kind, _, _ in fields:
            lines.append("        $model->%s = %s;" % (fname, php_read(fname, kind)))
        lines += ["", "        return $model;", "    }", "}", ""]
        write("php/src/Model/%s.php" % name, "\n".join(lines))


def ts_type(model, fname, kind):
    if (model, fname) in ENUMS:
        return model + fname[0].upper() + fname[1:]
    if kind == "s":
        return "string"
    if kind in ("i", "f"):
        return "number"
    if kind == "b":
        return "boolean"
    if kind == "t":
        return "string"
    if kind == "[s]":
        return "string[]"
    if kind == "{f}":
        return "Record<string, number>"
    if kind.startswith("["):
        return kind[1:-1] + "[]"
    if kind.startswith("{"):
        return "Record<string, %s>" % kind[1:-1]
    return kind


def gen_ts():
    lines = []
    for (model, fname), values in ENUMS.items():
        alias = model + fname[0].upper() + fname[1:]
        lines.append("export type %s = %s;" % (alias, " | ".join("'%s'" % v for v in values)))
    lines.append("")
    for name, desc, spec in MODELS:
        lines.append("export interface %s {" % name)
        for fname, kind, nullable, optional in parse(spec):
            t = ts_type(name, fname, kind)
            if nullable:
                t += " | null"
            lines.append("  %s%s: %s;" % (fname, "?" if optional else "", t))
        lines.append("}")
        lines.append("")
    lines.append("export type ZReport = Record<string, unknown>;")
    lines.append("")
    write("node/src/models.ts", "\n".join(lines))


def py_type(kind):
    if kind == "s":
        return "Optional[str]"
    if kind == "i":
        return "Optional[int]"
    if kind == "f":
        return "Optional[float]"
    if kind == "b":
        return "Optional[bool]"
    if kind == "t":
        return "Optional[datetime]"
    if kind == "[s]":
        return "List[str]"
    if kind == "{f}":
        return "Dict[str, float]"
    if kind.startswith("["):
        return "List[%s]" % kind[1:-1]
    if kind.startswith("{"):
        return "Dict[str, %s]" % kind[1:-1]
    return "Optional[%s]" % kind


def py_default(kind):
    if kind.startswith("["):
        return "field(default_factory=list)"
    if kind.startswith("{"):
        return "field(default_factory=dict)"
    return "None"


def py_read(fname, kind):
    key = '"%s"' % fname
    if kind == "s":
        return "_str(data.get(%s))" % key
    if kind == "i":
        return "_int(data.get(%s))" % key
    if kind == "f":
        return "_float(data.get(%s))" % key
    if kind == "b":
        return "_bool(data.get(%s))" % key
    if kind == "t":
        return "_datetime(data.get(%s))" % key
    if kind == "[s]":
        return "_strings(data.get(%s))" % key
    if kind == "{f}":
        return "_floats(data.get(%s))" % key
    if kind.startswith("["):
        return "_list_of(data.get(%s), %s)" % (key, kind[1:-1])
    if kind.startswith("{"):
        return "_map_of(data.get(%s), %s)" % (key, kind[1:-1])
    return "_object(data.get(%s), %s)" % (key, kind)


def gen_py():
    lines = [
        "from __future__ import annotations",
        "",
        "from dataclasses import dataclass, field",
        "from datetime import datetime",
        "from typing import Any, Dict, List, Mapping, Optional",
        "",
        "from ._convert import _bool, _datetime, _float, _floats, _int, _list_of, _map_of, _object, _str, _strings",
        "",
        "__all__ = [",
    ]
    for name, _, _ in MODELS:
        lines.append('    "%s",' % name)
    lines += ["]", "", ""]
    for name, desc, spec in MODELS:
        fields = parse(spec)
        lines.append("@dataclass(frozen=True)")
        lines.append("class %s:" % name)
        for fname, kind, _, _ in fields:
            lines.append("    %s: %s = %s" % (snake(fname), py_type(kind), py_default(kind)))
        lines.append("    raw: Dict[str, Any] = field(default_factory=dict, repr=False, compare=False)")
        lines += [
            "",
            "    @classmethod",
            "    def from_dict(cls, data: Mapping[str, Any]) -> \"%s\":" % name,
            "        return cls(",
        ]
        for fname, kind, _, _ in fields:
            lines.append("            %s=%s," % (snake(fname), py_read(fname, kind)))
        lines += ["            raw=dict(data),", "        )", "", ""]
    write("python/src/noosh24/models.py", "\n".join(lines).rstrip() + "\n")


if __name__ == "__main__":
    targets = sys.argv[1:] or ["php", "ts", "py"]
    if "php" in targets:
        gen_php()
    if "ts" in targets:
        gen_ts()
    if "py" in targets:
        gen_py()
