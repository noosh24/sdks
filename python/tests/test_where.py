from __future__ import annotations

from datetime import date, datetime, timedelta, timezone

import pytest

from noosh24 import Where, literal, where


def test_builds_and_only_conditions():
    baku = timezone(timedelta(hours=4))
    text = str(
        where()
        .eq("category", "Salads")
        .ne("station", "")
        .gt("price", 4.75)
        .lte("prepMinutes", 15)
        .eq("vegetarian", False)
        .gte("createdAt", datetime(2026, 11, 1, 18, 0, tzinfo=baku))
        .lt("visitedOn", date(2026, 11, 2))
        .lt("price", 20.0)
        .in_("id", ["7f0c", "O'Neil", 3])
    )

    assert text == (
        "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false"
        " AND createdAt >= '2026-11-01T18:00:00+04:00' AND visitedOn < '2026-11-02' AND price < 20"
        " AND id in ('7f0c', 'O''Neil', 3)"
    )


def test_empty_is_empty_string():
    assert str(Where()) == ""


def test_rejects_bad_input():
    with pytest.raises(ValueError):
        where().eq("price = 1 OR 1", 1)
    with pytest.raises(ValueError):
        where().in_("id", [])
    with pytest.raises(ValueError):
        where().gt("price", float("nan"))
    with pytest.raises(ValueError):
        where().gt("createdAt", datetime(2026, 11, 1))
    with pytest.raises(TypeError):
        literal(None)
