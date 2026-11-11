use chrono::{FixedOffset, NaiveDate, TimeZone, Utc};
use noosh24::{Error, Where, WhereValue, literal};

#[test]
fn builds_and_only_conditions() {
    let baku = FixedOffset::east_opt(4 * 3600).unwrap();
    let text = Where::new()
        .eq("category", "Salads")
        .ne("station", "")
        .gt("price", 4.75)
        .lte("prepMinutes", 15)
        .eq("vegetarian", false)
        .gte("createdAt", baku.with_ymd_and_hms(2026, 11, 1, 18, 0, 0).unwrap())
        .lt("price", 20.0)
        .in_(
            "id",
            [
                WhereValue::from("7f0c"),
                WhereValue::from("O'Neil"),
                WhereValue::from(3),
            ],
        )
        .build()
        .unwrap();

    assert_eq!(
        text,
        "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)"
    );
}

#[test]
fn dates_and_utc_times() {
    let text = Where::new()
        .lt("visitedOn", NaiveDate::from_ymd_opt(2026, 11, 2).unwrap())
        .gte("createdAt", Utc.with_ymd_and_hms(2026, 11, 1, 14, 0, 0).unwrap())
        .in_("status", ["served", "ready"])
        .build()
        .unwrap();

    assert_eq!(
        text,
        "visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00+00:00' AND status in ('served', 'ready')"
    );
}

#[test]
fn empty_is_empty_string() {
    assert_eq!(Where::new().build().unwrap(), "");
    assert!(Where::new().is_empty());
}

#[test]
fn rejects_bad_input() {
    let invalid = |w: Where| matches!(w.build(), Err(Error::InvalidArgument(_)));
    assert!(invalid(Where::new().eq("price = 1 OR 1", 1)));
    assert!(invalid(Where::new().eq("", 1)));
    assert!(invalid(Where::new().eq("1price", 1)));
    assert!(invalid(Where::new().in_("id", Vec::<&str>::new())));
    assert!(invalid(Where::new().gt("price", f64::NAN)));
    assert!(invalid(Where::new().gt("price", f64::INFINITY)));
    assert!(invalid(Where::new().eq("note", None::<&str>)));
    assert!(invalid(Where::new().eq("a", 1).eq("b c", 2).eq("d", 3)));
    assert!(!Where::new().eq("b c", 2).is_empty());
    assert!(literal(&WhereValue::Null).is_err());
}

#[test]
fn literals() {
    assert_eq!(literal(&WhereValue::from(true)).unwrap(), "true");
    assert_eq!(literal(&WhereValue::from(-3i64)).unwrap(), "-3");
    assert_eq!(literal(&WhereValue::from(20.0)).unwrap(), "20");
    assert_eq!(literal(&WhereValue::from(4.75)).unwrap(), "4.75");
    assert_eq!(literal(&WhereValue::from(Some("x"))).unwrap(), "'x'");
    assert_eq!(literal(&WhereValue::from("Chef's")).unwrap(), "'Chef''s'");
    assert_eq!(literal(&WhereValue::from(String::from("a.b"))).unwrap(), "'a.b'");
    assert!(Where::new().eq("menu.category_id", 1).build().is_ok());
}
