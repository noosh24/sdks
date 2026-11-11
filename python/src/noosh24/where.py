from __future__ import annotations

import math
import re
from collections.abc import Iterable
from datetime import date, datetime

__all__ = ["Where", "where", "literal"]

WhereValue = str | int | float | bool | date | datetime

_FIELD = re.compile(r"^[A-Za-z][A-Za-z0-9_.]*$")


def literal(value: WhereValue) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, datetime):
        if value.tzinfo is None:
            raise ValueError("where needs a timezone-aware datetime")
        return f"'{value.isoformat()}'"
    if isinstance(value, date):
        return f"'{value.isoformat()}'"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("Numbers in where must be finite")
        return repr(value) if value != int(value) else str(int(value))
    if isinstance(value, str):
        return "'{}'".format(value.replace("'", "''"))
    raise TypeError("where takes strings, numbers, booleans and dates")


def _field(name: str) -> str:
    if not isinstance(name, str) or not _FIELD.match(name):
        raise ValueError(f'"{name}" is not a field name')
    return name


class Where:
    def __init__(self) -> None:
        self._conditions: list[str] = []

    def eq(self, field: str, value: WhereValue) -> Where:
        return self._add(field, "=", value)

    def ne(self, field: str, value: WhereValue) -> Where:
        return self._add(field, "!=", value)

    def gt(self, field: str, value: WhereValue) -> Where:
        return self._add(field, ">", value)

    def gte(self, field: str, value: WhereValue) -> Where:
        return self._add(field, ">=", value)

    def lt(self, field: str, value: WhereValue) -> Where:
        return self._add(field, "<", value)

    def lte(self, field: str, value: WhereValue) -> Where:
        return self._add(field, "<=", value)

    def in_(self, field: str, values: Iterable[WhereValue]) -> Where:
        items = list(values)
        if not items:
            raise ValueError("in_() needs at least one value")
        self._conditions.append("{} in ({})".format(_field(field), ", ".join(literal(v) for v in items)))
        return self

    def __str__(self) -> str:
        return " AND ".join(self._conditions)

    def __repr__(self) -> str:
        return f"Where({str(self)!r})"

    def _add(self, field: str, operator: str, value: WhereValue) -> Where:
        self._conditions.append(f"{_field(field)} {operator} {literal(value)}")
        return self


def where() -> Where:
    return Where()
