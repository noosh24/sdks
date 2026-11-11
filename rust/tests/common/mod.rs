#![allow(dead_code)]

use std::collections::{BTreeMap, VecDeque};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use noosh24::{BoxFuture, Client, ClientBuilder, HttpRequest, HttpResponse, Transport, TransportError};
use serde_json::{Value, json};

#[derive(Clone, Default)]
pub struct Mock {
    state: Arc<Mutex<State>>,
}

#[derive(Default)]
struct State {
    queue: VecDeque<Result<HttpResponse, TransportError>>,
    requests: Vec<HttpRequest>,
}

impl Mock {
    pub fn json(&self, status: u16, body: Value) -> &Self {
        self.json_with(status, body, &[])
    }

    pub fn json_with(&self, status: u16, body: Value, headers: &[(&str, &str)]) -> &Self {
        let mut all = vec![("Content-Type".to_owned(), "application/json".to_owned())];
        all.extend(
            headers
                .iter()
                .map(|(name, value)| ((*name).to_owned(), (*value).to_owned())),
        );
        self.push(Ok(HttpResponse::new(status, all, body.to_string())))
    }

    pub fn raw(&self, status: u16, text: &str) -> &Self {
        self.push(Ok(HttpResponse::new(status, Vec::new(), text)))
    }

    pub fn fail(&self, error: TransportError) -> &Self {
        self.push(Err(error))
    }

    fn push(&self, item: Result<HttpResponse, TransportError>) -> &Self {
        self.state.lock().unwrap().queue.push_back(item);
        self
    }

    pub fn requests(&self) -> Vec<HttpRequest> {
        self.state.lock().unwrap().requests.clone()
    }

    pub fn count(&self) -> usize {
        self.state.lock().unwrap().requests.len()
    }

    pub fn last(&self) -> HttpRequest {
        self.requests().pop().expect("no request was sent")
    }
}

impl Transport for Mock {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, TransportError>> {
        let mut state = self.state.lock().unwrap();
        let description = format!("{} {}", request.method, request.url);
        state.requests.push(request);
        let next = state.queue.pop_front();
        Box::pin(async move { next.unwrap_or_else(|| panic!("No response queued for {description}")) })
    }
}

#[derive(Clone, Default)]
pub struct Sleeps(Arc<Mutex<Vec<Duration>>>);

impl Sleeps {
    pub fn seconds(&self) -> Vec<f64> {
        self.0.lock().unwrap().iter().map(Duration::as_secs_f64).collect()
    }
}

pub struct Setup {
    pub client: Client,
    pub http: Mock,
    pub sleeps: Sleeps,
}

pub fn setup() -> Setup {
    setup_with(|builder| builder)
}

pub fn setup_with(configure: impl FnOnce(ClientBuilder) -> ClientBuilder) -> Setup {
    let http = Mock::default();
    let sleeps = Sleeps::default();
    let recorded = sleeps.clone();
    let builder = Client::builder()
        .api_key("nsk_test_123")
        .transport(http.clone())
        .sleep(move |duration| {
            recorded.0.lock().unwrap().push(duration);
            async {}
        });
    let client = configure(builder).build().expect("client");
    Setup { client, http, sleeps }
}

pub fn query(request: &HttpRequest) -> BTreeMap<String, Vec<String>> {
    let url = reqwest::Url::parse(&request.url).expect("url");
    let mut out: BTreeMap<String, Vec<String>> = BTreeMap::new();
    for (name, value) in url.query_pairs() {
        out.entry(name.into_owned()).or_default().push(value.into_owned());
    }
    out
}

pub fn expect_query(pairs: &[(&str, &[&str])]) -> BTreeMap<String, Vec<String>> {
    pairs
        .iter()
        .map(|(name, values)| ((*name).to_owned(), values.iter().map(|v| (*v).to_owned()).collect()))
        .collect()
}

pub fn path(request: &HttpRequest) -> String {
    reqwest::Url::parse(&request.url).expect("url").path().to_owned()
}

pub fn body(request: &HttpRequest) -> Value {
    serde_json::from_slice(request.body.as_deref().expect("body")).expect("json body")
}

pub fn page(items: Value, total: u64, limit: u64, offset: u64) -> Value {
    json!({"data": {"items": items, "total": total, "limit": limit, "offset": offset}})
}
