package noosh24

import (
	"errors"
	"math"
	"testing"
	"time"
)

func TestBuildsAndOnlyConditions(t *testing.T) {
	baku := time.FixedZone("Baku", 4*60*60)
	w := NewWhere().
		Eq("category", "Salads").
		Ne("station", "").
		Gt("price", 4.75).
		Lte("prepMinutes", 15).
		Eq("vegetarian", false).
		Gte("createdAt", time.Date(2026, 11, 1, 18, 0, 0, 0, baku)).
		Lt("price", 20.0).
		In("id", "7f0c", "O'Neil", 3)

	text, err := w.Build()

	equal(t, err, nil)
	equal(t, text, "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)")
	equal(t, w.String(), text)
}

func TestPlainDatesAndUTC(t *testing.T) {
	text, err := NewWhere().
		Lt("visitedOn", NewDate(2026, time.November, 2)).
		Gte("createdAt", time.Date(2026, 11, 1, 14, 0, 0, 500000000, time.UTC)).
		Eq("guests", int64(4)).
		Eq("price", float32(2.5)).
		Build()

	equal(t, err, nil)
	equal(t, text, "visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00.5Z' AND guests = 4 AND price = 2.5")
	equal(t, DateOf(time.Date(2026, 1, 9, 23, 0, 0, 0, time.UTC)).String(), "2026-01-09")
}

func TestEmptyIsEmptyString(t *testing.T) {
	equal(t, NewWhere().String(), "")
	var w Where
	equal(t, w.String(), "")
}

func TestRejectsBadInput(t *testing.T) {
	cases := map[string]*Where{
		"field":       NewWhere().Eq("price = 1 OR 1", 1),
		"empty in":    NewWhere().In("id"),
		"nan":         NewWhere().Gt("price", math.NaN()),
		"inf":         NewWhere().Gt("price", math.Inf(1)),
		"nil":         NewWhere().Eq("note", nil),
		"type":        NewWhere().Eq("note", []string{"a"}),
		"zero time":   NewWhere().Gt("createdAt", time.Time{}),
		"in value":    NewWhere().In("id", "a", nil),
		"first error": NewWhere().Eq("1bad", 1).Eq("ok", 2),
	}
	for name, w := range cases {
		if _, err := w.Build(); !errors.Is(err, ErrInvalidArgument) {
			t.Fatalf("%s: err = %v", name, err)
		}
		if !errors.Is(w.Err(), ErrInvalidArgument) {
			t.Fatalf("%s: Err() = %v", name, w.Err())
		}
	}
	if _, err := Literal(nil); !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("Literal(nil) = %v", err)
	}
}

func TestBadWhereStopsTheRequest(t *testing.T) {
	m := newMock(t)

	_, err := m.client().Orders.List(ctx(), &ListParams{Where: NewWhere().In("id")})

	if !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 0)
}
