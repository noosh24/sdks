use chrono::{NaiveDate, NaiveTime};
use futures::stream::{self, Stream, TryStreamExt};
use percent_encoding::utf8_percent_encode;
use serde::de::DeserializeOwned;
use serde_json::{Map, Value};

use crate::client::{COMPONENT, Client, Query};
use crate::de::{from_object, number_i64};
use crate::error::{Error, Result};
use crate::models::{
    Bill, Category, Customer, Hall, Ingredient, LoyaltyCard, LoyaltyProgram, Order, Payment, Product, Reservation,
    Review, StockMove, StockStore, StopListItem, Table, TableAvailability, ZReport,
};
use crate::pagination::Page;
use crate::params::{CreateReservationResult, ListParams, ListQuery, NewReservation};

const PAGE_SIZE: u64 = 100;
const BILL_PAGE_SIZE: u64 = 50;
const EXPANDED_PAGE_SIZE: u64 = 50;

fn path_id(id: &str) -> Result<String> {
    if id.trim().is_empty() {
        return Err(Error::invalid("An id is required"));
    }
    Ok(utf8_percent_encode(id, COMPONENT).to_string())
}

fn items<T: DeserializeOwned>(value: Option<Value>) -> Vec<T> {
    match value {
        Some(Value::Array(items)) => items.into_iter().filter_map(from_object).collect(),
        _ => Vec::new(),
    }
}

fn object(value: Value) -> Map<String, Value> {
    match value {
        Value::Object(map) => map,
        _ => Map::new(),
    }
}

pub(crate) async fn one<T: DeserializeOwned + Default>(client: &Client, path: String, query: Query) -> Result<T> {
    let (_, data) = client.request("GET", &path, &query, None, true).await?;
    Ok(from_object(data).unwrap_or_default())
}

async fn all<T: DeserializeOwned>(client: &Client, path: &str) -> Result<Vec<T>> {
    let (_, data) = client.request("GET", path, &Vec::new(), None, true).await?;
    Ok(items(object(data).remove("items")))
}

async fn fetch_page<T: DeserializeOwned>(client: &Client, path: &str, query: &ListQuery) -> Result<Page<T>> {
    let (_, data) = client.request("GET", path, &query.pairs(), None, true).await?;
    let mut data = object(data);
    let items: Vec<T> = items(data.remove("items"));
    let count = items.len() as u64;
    let number = |key: &str| data.get(key).and_then(number_i64).map(|value| value.max(0) as u64);
    let total = number("total").unwrap_or(count);
    let limit = number("limit").or(query.limit).unwrap_or(count);
    let offset = number("offset").or(query.offset).unwrap_or(0);
    Ok(Page::new(items, total, limit, offset))
}

async fn list<T: DeserializeOwned>(client: &Client, path: &str, params: ListParams) -> Result<Page<T>> {
    fetch_page(client, path, &ListQuery::new(params, false)?).await
}

fn paginate<T>(
    client: &Client,
    path: &'static str,
    query: Result<ListQuery>,
    page_size: u64,
) -> impl Stream<Item = Result<T>> + Send + Unpin + use<T>
where
    T: DeserializeOwned + Send + 'static,
{
    let client = client.clone();
    let start = query.map(|mut query| {
        query.limit.get_or_insert(page_size);
        query.offset.get_or_insert(0);
        query
    });
    Box::pin(
        stream::try_unfold(Some(start), move |state| next_page::<T>(client.clone(), path, state))
            .map_ok(|items| stream::iter(items.into_iter().map(Ok::<T, Error>)))
            .try_flatten(),
    )
}

type PageState = Option<Result<ListQuery>>;

async fn next_page<T: DeserializeOwned>(
    client: Client,
    path: &'static str,
    state: PageState,
) -> Result<Option<(Vec<T>, PageState)>> {
    let mut query = match state {
        Some(query) => query?,
        None => return Ok(None),
    };
    let page: Page<T> = fetch_page(&client, path, &query).await?;
    let next = if page.has_more() {
        query.offset = Some(page.next_offset());
        Some(Ok(query))
    } else {
        None
    };
    Ok(Some((page.items, next)))
}

fn iterate<T>(
    client: &Client,
    path: &'static str,
    params: ListParams,
    page_size: u64,
) -> impl Stream<Item = Result<T>> + Send + Unpin + use<T>
where
    T: DeserializeOwned + Send + 'static,
{
    paginate(client, path, ListQuery::new(params, false), page_size)
}

macro_rules! resource {
    ($($name:ident),+) => {
        $(
            #[derive(Debug, Clone, Copy)]
            pub struct $name<'a> {
                client: &'a Client,
            }

            impl<'a> $name<'a> {
                pub(crate) fn new(client: &'a Client) -> Self {
                    Self { client }
                }
            }
        )+
    };
}

resource!(
    Menu,
    Reservations,
    Orders,
    Payments,
    Tables,
    Customers,
    Loyalty,
    Stock,
    Reviews
);

impl Menu<'_> {
    pub async fn list_categories(&self) -> Result<Vec<Category>> {
        all(self.client, "/menu/categories").await
    }

    pub async fn list_products(&self, params: ListParams) -> Result<Page<Product>> {
        fetch_page(self.client, "/menu/products", &ListQuery::new(params, true)?).await
    }

    pub fn iterate_products(&self, params: ListParams) -> impl Stream<Item = Result<Product>> + Send + Unpin + use<> {
        let page_size = if params.expand.iter().any(|value| !value.is_empty()) {
            EXPANDED_PAGE_SIZE
        } else {
            PAGE_SIZE
        };
        paginate(self.client, "/menu/products", ListQuery::new(params, true), page_size)
    }

    pub async fn get_product(&self, product_id: &str, expand: &[&str]) -> Result<Product> {
        let path = format!("/menu/products/{}", path_id(product_id)?);
        let query: Query = expand
            .iter()
            .filter(|value| !value.is_empty())
            .map(|value| ("expand", (*value).to_owned()))
            .collect();
        one(self.client, path, query).await
    }

    pub async fn get_stop_list(&self) -> Result<Vec<StopListItem>> {
        all(self.client, "/menu/stop-list").await
    }
}

impl Reservations<'_> {
    pub async fn list(&self, params: ListParams) -> Result<Page<Reservation>> {
        list(self.client, "/reservations", params).await
    }

    pub fn iterate(&self, params: ListParams) -> impl Stream<Item = Result<Reservation>> + Send + Unpin + use<> {
        iterate(self.client, "/reservations", params, PAGE_SIZE)
    }

    pub async fn get(&self, reservation_id: &str) -> Result<Reservation> {
        one(
            self.client,
            format!("/reservations/{}", path_id(reservation_id)?),
            Vec::new(),
        )
        .await
    }

    pub async fn availability(
        &self,
        date: NaiveDate,
        time: NaiveTime,
        guests: Option<u32>,
    ) -> Result<TableAvailability> {
        let mut query: Query = vec![
            ("date", date.format("%Y-%m-%d").to_string()),
            ("time", time.format("%H:%M").to_string()),
        ];
        if let Some(guests) = guests {
            query.push(("guests", guests.to_string()));
        }
        one(self.client, "/reservations/availability".to_owned(), query).await
    }

    pub async fn create(&self, reservation: &NewReservation) -> Result<CreateReservationResult> {
        let body = serde_json::to_vec(reservation).map_err(|error| Error::invalid(error.to_string()))?;
        let (status, data) = self
            .client
            .request(
                "POST",
                "/reservations",
                &Vec::new(),
                Some(body),
                reservation.is_idempotent(),
            )
            .await?;
        Ok(CreateReservationResult {
            reservation: from_object(data).unwrap_or_default(),
            created: status == 201,
        })
    }

    pub async fn cancel(&self, reservation_id: &str) -> Result<Reservation> {
        let path = format!("/reservations/{}/cancel", path_id(reservation_id)?);
        let (_, data) = self.client.request("POST", &path, &Vec::new(), None, true).await?;
        Ok(from_object(data).unwrap_or_default())
    }
}

impl Orders<'_> {
    pub async fn list(&self, params: ListParams) -> Result<Page<Order>> {
        list(self.client, "/orders", params).await
    }

    pub fn iterate(&self, params: ListParams) -> impl Stream<Item = Result<Order>> + Send + Unpin + use<> {
        iterate(self.client, "/orders", params, PAGE_SIZE)
    }

    pub async fn get(&self, order_id: &str) -> Result<Order> {
        one(self.client, format!("/orders/{}", path_id(order_id)?), Vec::new()).await
    }

    pub async fn list_bills(&self, params: ListParams) -> Result<Page<Bill>> {
        list(self.client, "/bills", params).await
    }

    pub fn iterate_bills(&self, params: ListParams) -> impl Stream<Item = Result<Bill>> + Send + Unpin + use<> {
        iterate(self.client, "/bills", params, BILL_PAGE_SIZE)
    }

    pub async fn get_bill(&self, bill_id: &str) -> Result<Bill> {
        one(self.client, format!("/bills/{}", path_id(bill_id)?), Vec::new()).await
    }
}

impl Payments<'_> {
    pub async fn list(&self, params: ListParams) -> Result<Page<Payment>> {
        list(self.client, "/payments", params).await
    }

    pub fn iterate(&self, params: ListParams) -> impl Stream<Item = Result<Payment>> + Send + Unpin + use<> {
        iterate(self.client, "/payments", params, PAGE_SIZE)
    }

    pub async fn get(&self, payment_id: &str) -> Result<Payment> {
        one(self.client, format!("/payments/{}", path_id(payment_id)?), Vec::new()).await
    }

    pub async fn z_report(&self, date: Option<NaiveDate>) -> Result<ZReport> {
        let query: Query = date
            .map(|date| vec![("date", date.format("%Y-%m-%d").to_string())])
            .unwrap_or_default();
        let (_, data) = self.client.request("GET", "/reports/z", &query, None, true).await?;
        Ok(object(data))
    }
}

impl Tables<'_> {
    pub async fn list(&self) -> Result<Vec<Table>> {
        all(self.client, "/tables").await
    }

    pub async fn list_halls(&self) -> Result<Vec<Hall>> {
        all(self.client, "/halls").await
    }
}

impl Customers<'_> {
    pub async fn list(&self, params: ListParams) -> Result<Page<Customer>> {
        list(self.client, "/customers", params).await
    }

    pub fn iterate(&self, params: ListParams) -> impl Stream<Item = Result<Customer>> + Send + Unpin + use<> {
        iterate(self.client, "/customers", params, PAGE_SIZE)
    }

    pub async fn get(&self, customer_id: &str) -> Result<Customer> {
        one(self.client, format!("/customers/{}", path_id(customer_id)?), Vec::new()).await
    }
}

impl Loyalty<'_> {
    pub async fn get_program(&self) -> Result<LoyaltyProgram> {
        one(self.client, "/loyalty/program".to_owned(), Vec::new()).await
    }

    pub async fn list_cards(&self, params: ListParams) -> Result<Page<LoyaltyCard>> {
        list(self.client, "/loyalty/cards", params).await
    }

    pub fn iterate_cards(&self, params: ListParams) -> impl Stream<Item = Result<LoyaltyCard>> + Send + Unpin + use<> {
        iterate(self.client, "/loyalty/cards", params, PAGE_SIZE)
    }
}

impl Stock<'_> {
    pub async fn list_ingredients(&self, params: ListParams) -> Result<Page<Ingredient>> {
        list(self.client, "/stock/ingredients", params).await
    }

    pub fn iterate_ingredients(
        &self,
        params: ListParams,
    ) -> impl Stream<Item = Result<Ingredient>> + Send + Unpin + use<> {
        iterate(self.client, "/stock/ingredients", params, PAGE_SIZE)
    }

    pub async fn list_moves(&self, params: ListParams) -> Result<Page<StockMove>> {
        list(self.client, "/stock/moves", params).await
    }

    pub fn iterate_moves(&self, params: ListParams) -> impl Stream<Item = Result<StockMove>> + Send + Unpin + use<> {
        iterate(self.client, "/stock/moves", params, PAGE_SIZE)
    }

    pub async fn list_stores(&self) -> Result<Vec<StockStore>> {
        all(self.client, "/stock/stores").await
    }
}

impl Reviews<'_> {
    pub async fn list(&self, params: ListParams) -> Result<Page<Review>> {
        list(self.client, "/reviews", params).await
    }

    pub fn iterate(&self, params: ListParams) -> impl Stream<Item = Result<Review>> + Send + Unpin + use<> {
        iterate(self.client, "/reviews", params, PAGE_SIZE)
    }
}
