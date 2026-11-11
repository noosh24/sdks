use std::time::Duration;

use futures::TryStreamExt;
use noosh24::chrono::{FixedOffset, NaiveDate, NaiveTime, TimeZone};
use noosh24::{Client, ListParams, NewReservation, PreOrderLine, Where};

async fn quick_start() -> noosh24::Result<()> {
    let noosh = Client::new(std::env::var("NOOSH24_API_KEY").unwrap_or_default())?;

    let me = noosh.whoami().await?;
    println!(
        "{:?} {:?}",
        me.restaurant.and_then(|r| r.name),
        me.key.map(|k| k.scopes)
    );

    let page = noosh
        .menu()
        .list_products(ListParams {
            where_: Some(Where::new().eq("category", "Salads").eq("available", true).into()),
            sort: vec!["price desc".into()],
            limit: Some(50),
            ..Default::default()
        })
        .await?;
    for product in &page {
        println!("{:?} {:?}", product.name, product.price);
    }
    println!("{} products match", page.total);
    Ok(())
}

async fn options_lists_and_reservations() -> noosh24::Result<()> {
    let noosh = noosh24::Client::builder()
        .api_key("nsk_...")
        .base_url("https://open-api.noosh24.com/v1")
        .timeout(Duration::from_secs(30))
        .max_retries(2)
        .user_agent("acme-pos/2.1")
        .build()?;

    let orders = noosh
        .orders()
        .list(
            ListParams::new()
                .where_("status = 'served' AND createdAt >= '2026-11-01'")
                .sort("createdAt desc")
                .limit(100),
        )
        .await?;
    println!("{}", orders.total);

    let baku = FixedOffset::east_opt(4 * 3600).unwrap();
    let condition = Where::new()
        .eq("status", "confirmed")
        .gte("startsAt", baku.with_ymd_and_hms(2026, 11, 20, 0, 0, 0).unwrap())
        .in_("zone", ["Terrace", "Chef's table"]);
    noosh.reservations().list(ListParams::new().where_(condition)).await?;

    let mut payments = noosh
        .payments()
        .iterate(ListParams::new().where_("createdAt >= '2026-11-01'"));
    while let Some(payment) = payments.try_next().await? {
        println!("{:?} {:?}", payment.id, payment.amount);
    }

    let date = NaiveDate::from_ymd_opt(2026, 11, 20).unwrap();
    let time = NaiveTime::from_hms_opt(19, 30, 0).unwrap();
    let free = noosh.reservations().availability(date, time, Some(4)).await?;

    let booking = NewReservation::new(date, time, 4, "Aysel Məmmədova", "+994501234567")
        .table_id(free.tables[0].id.clone().unwrap_or_default())
        .pre_order(PreOrderLine::new("0b6f3c1e", 2))
        .external_ref("acme-booking-991");

    match noosh.reservations().create(&booking).await {
        Ok(result) => {
            println!(
                "{:?} {}",
                result.reservation.code,
                if result.created { "created" } else { "already existed" }
            );
            noosh
                .reservations()
                .cancel(result.reservation.id.as_deref().unwrap_or_default())
                .await?;
        }
        Err(error) if error.is_table_taken() => println!("pick another table"),
        Err(error) => return Err(error),
    }
    Ok(())
}

#[tokio::main]
async fn main() -> noosh24::Result<()> {
    if std::env::var("NOOSH24_API_KEY").is_err() {
        eprintln!("set NOOSH24_API_KEY to run this example");
        return Ok(());
    }
    quick_start().await?;
    if std::env::var("NOOSH24_EXAMPLE_WRITE").is_ok() {
        options_lists_and_reservations().await?;
    }
    Ok(())
}
