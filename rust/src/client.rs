use std::collections::BTreeMap;
use std::fmt;
use std::future::Future;
use std::sync::Arc;
use std::time::Duration;

use percent_encoding::{AsciiSet, NON_ALPHANUMERIC, utf8_percent_encode};
use serde_json::Value;

use crate::error::{ApiError, Error, Result};
use crate::models::Whoami;
use crate::resources::{self, Customers, Loyalty, Menu, Orders, Payments, Reservations, Reviews, Stock, Tables};
use crate::transport::{BoxFuture, HttpRequest, ReqwestTransport, Transport};

pub const DEFAULT_BASE_URL: &str = "https://open-api.noosh24.com/v1";

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

const RETRY_STATUSES: [u16; 4] = [429, 502, 503, 504];
const MAX_RETRY_WAIT: f64 = 60.0;

pub(crate) const COMPONENT: &AsciiSet = &NON_ALPHANUMERIC.remove(b'-').remove(b'_').remove(b'.').remove(b'~');

pub(crate) type Query = Vec<(&'static str, String)>;

type SleepFn = Arc<dyn Fn(Duration) -> BoxFuture<'static, ()> + Send + Sync>;

#[derive(Clone)]
pub struct Client {
    inner: Arc<Inner>,
}

struct Inner {
    api_key: String,
    base_url: String,
    timeout: Duration,
    max_retries: u32,
    user_agent: String,
    transport: Arc<dyn Transport>,
    sleep: SleepFn,
}

impl fmt::Debug for Client {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Client")
            .field("base_url", &self.inner.base_url)
            .field("timeout", &self.inner.timeout)
            .field("max_retries", &self.inner.max_retries)
            .field("user_agent", &self.inner.user_agent)
            .finish_non_exhaustive()
    }
}

pub struct ClientBuilder {
    api_key: Option<String>,
    base_url: Option<String>,
    timeout: Duration,
    max_retries: u32,
    user_agent: Option<String>,
    transport: Option<Arc<dyn Transport>>,
    sleep: Option<SleepFn>,
}

impl fmt::Debug for ClientBuilder {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("ClientBuilder")
            .field("base_url", &self.base_url)
            .field("timeout", &self.timeout)
            .field("max_retries", &self.max_retries)
            .field("user_agent", &self.user_agent)
            .finish_non_exhaustive()
    }
}

impl Default for ClientBuilder {
    fn default() -> Self {
        Self {
            api_key: None,
            base_url: None,
            timeout: Duration::from_secs(30),
            max_retries: 2,
            user_agent: None,
            transport: None,
            sleep: None,
        }
    }
}

impl ClientBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn api_key(mut self, api_key: impl Into<String>) -> Self {
        self.api_key = Some(api_key.into());
        self
    }

    pub fn base_url(mut self, base_url: impl Into<String>) -> Self {
        self.base_url = Some(base_url.into());
        self
    }

    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    pub fn max_retries(mut self, max_retries: u32) -> Self {
        self.max_retries = max_retries;
        self
    }

    pub fn user_agent(mut self, user_agent: impl Into<String>) -> Self {
        self.user_agent = Some(user_agent.into());
        self
    }

    pub fn http_client(self, client: reqwest::Client) -> Self {
        self.transport(ReqwestTransport::new(client))
    }

    pub fn transport(mut self, transport: impl Transport) -> Self {
        self.transport = Some(Arc::new(transport));
        self
    }

    pub fn sleep<F, Fut>(mut self, sleep: F) -> Self
    where
        F: Fn(Duration) -> Fut + Send + Sync + 'static,
        Fut: Future<Output = ()> + Send + 'static,
    {
        self.sleep = Some(Arc::new(move |duration| Box::pin(sleep(duration))));
        self
    }

    pub fn build(self) -> Result<Client> {
        let api_key = self.api_key.as_deref().unwrap_or_default().trim().to_owned();
        if api_key.is_empty() {
            return Err(Error::invalid("An API key is required"));
        }
        let base_url = self
            .base_url
            .as_deref()
            .unwrap_or(DEFAULT_BASE_URL)
            .trim()
            .trim_end_matches('/')
            .to_owned();
        match reqwest::Url::parse(&base_url) {
            Ok(url) if matches!(url.scheme(), "http" | "https") => {}
            _ => return Err(Error::invalid(format!("\"{base_url}\" is not an http(s) base URL"))),
        }
        let agent = format!("noosh24-rust/{VERSION}");
        let user_agent = match self.user_agent.as_deref().map(str::trim) {
            Some(prefix) if !prefix.is_empty() => format!("{prefix} {agent}"),
            _ => agent,
        };
        let transport = match self.transport {
            Some(transport) => transport,
            None => Arc::new(ReqwestTransport::try_default().map_err(|error| Error::Connection {
                message: format!("Could not set up the HTTP client: {error}"),
                source: Some(error.into_source()),
            })?),
        };
        let sleep = self
            .sleep
            .unwrap_or_else(|| Arc::new(|duration| Box::pin(tokio::time::sleep(duration))));
        Ok(Client {
            inner: Arc::new(Inner {
                api_key,
                base_url,
                timeout: self.timeout,
                max_retries: self.max_retries,
                user_agent,
                transport,
                sleep,
            }),
        })
    }
}

impl Client {
    pub fn new(api_key: impl Into<String>) -> Result<Self> {
        Self::builder().api_key(api_key).build()
    }

    pub fn builder() -> ClientBuilder {
        ClientBuilder::new()
    }

    pub fn base_url(&self) -> &str {
        &self.inner.base_url
    }

    pub fn timeout(&self) -> Duration {
        self.inner.timeout
    }

    pub fn max_retries(&self) -> u32 {
        self.inner.max_retries
    }

    pub fn user_agent(&self) -> &str {
        &self.inner.user_agent
    }

    pub async fn whoami(&self) -> Result<Whoami> {
        resources::one(self, "/whoami".to_owned(), Vec::new()).await
    }

    pub fn menu(&self) -> Menu<'_> {
        Menu::new(self)
    }

    pub fn reservations(&self) -> Reservations<'_> {
        Reservations::new(self)
    }

    pub fn orders(&self) -> Orders<'_> {
        Orders::new(self)
    }

    pub fn payments(&self) -> Payments<'_> {
        Payments::new(self)
    }

    pub fn tables(&self) -> Tables<'_> {
        Tables::new(self)
    }

    pub fn customers(&self) -> Customers<'_> {
        Customers::new(self)
    }

    pub fn loyalty(&self) -> Loyalty<'_> {
        Loyalty::new(self)
    }

    pub fn stock(&self) -> Stock<'_> {
        Stock::new(self)
    }

    pub fn reviews(&self) -> Reviews<'_> {
        Reviews::new(self)
    }

    pub(crate) async fn request(
        &self,
        method: &'static str,
        path: &str,
        query: &Query,
        body: Option<Vec<u8>>,
        retryable: bool,
    ) -> Result<(u16, Value)> {
        let inner = &self.inner;
        let mut url = format!("{}{}", inner.base_url, path);
        if !query.is_empty() {
            url.push('?');
            url.push_str(&encode_query(query));
        }
        let mut headers = vec![
            ("Authorization".to_owned(), format!("Bearer {}", inner.api_key)),
            ("Accept".to_owned(), "application/json".to_owned()),
            ("User-Agent".to_owned(), inner.user_agent.clone()),
        ];
        if body.is_some() {
            headers.push(("Content-Type".to_owned(), "application/json".to_owned()));
        }

        let mut attempt: u32 = 0;
        loop {
            let request = HttpRequest {
                method,
                url: url.clone(),
                headers: headers.clone(),
                body: body.clone(),
                timeout: inner.timeout,
            };
            let response = match inner.transport.send(request).await {
                Ok(response) => response,
                Err(error) => {
                    if retryable && attempt < inner.max_retries {
                        (inner.sleep)(backoff(attempt)).await;
                        attempt += 1;
                        continue;
                    }
                    return Err(if error.is_timeout() {
                        Error::Timeout {
                            message: format!("Request timed out after {} s", inner.timeout.as_secs_f64()),
                            source: Some(error.into_source()),
                        }
                    } else {
                        Error::Connection {
                            message: format!("Could not reach the Noosh24 API: {error}"),
                            source: Some(error.into_source()),
                        }
                    });
                }
            };
            let response_headers = lower_headers(&response.headers);
            let text = String::from_utf8_lossy(&response.body).into_owned();
            if (200..300).contains(&response.status) {
                let data = decode(response.status, response_headers, text)?;
                return Ok((response.status, data));
            }
            if retryable
                && attempt < inner.max_retries
                && let Some(wait) = retry_wait(response.status, &response_headers, attempt)
            {
                (inner.sleep)(wait).await;
                attempt += 1;
                continue;
            }
            return Err(ApiError::from_response(response.status, response_headers, text).into());
        }
    }
}

pub(crate) fn encode_query(query: &Query) -> String {
    query
        .iter()
        .map(|(name, value)| {
            format!(
                "{}={}",
                utf8_percent_encode(name, COMPONENT),
                utf8_percent_encode(value, COMPONENT)
            )
        })
        .collect::<Vec<_>>()
        .join("&")
}

fn lower_headers(headers: &[(String, String)]) -> BTreeMap<String, String> {
    let mut out: BTreeMap<String, String> = BTreeMap::new();
    for (name, value) in headers {
        out.entry(name.to_ascii_lowercase())
            .and_modify(|existing| {
                existing.push_str(", ");
                existing.push_str(value);
            })
            .or_insert_with(|| value.clone());
    }
    out
}

fn decode(status: u16, headers: BTreeMap<String, String>, text: String) -> Result<Value> {
    if text.is_empty() {
        return Ok(Value::Null);
    }
    match serde_json::from_str::<Value>(&text) {
        Ok(Value::Object(mut parsed)) => match parsed.remove("data") {
            Some(data) => Ok(data),
            None => Err(ApiError::new(status, None, "The API answered without a \"data\" field", headers, text).into()),
        },
        Ok(_) => Err(ApiError::new(status, None, "The API answered without a \"data\" field", headers, text).into()),
        Err(_) => Err(ApiError::new(
            status,
            None,
            "The API answered with a body that is not JSON",
            headers,
            text,
        )
        .into()),
    }
}

fn retry_wait(status: u16, headers: &BTreeMap<String, String>, attempt: u32) -> Option<Duration> {
    if !RETRY_STATUSES.contains(&status) {
        return None;
    }
    let Some(header) = headers.get("retry-after") else {
        return Some(backoff(attempt));
    };
    match header.trim().parse::<f64>() {
        Ok(seconds) if !seconds.is_nan() => {
            let seconds = seconds.max(0.0);
            (seconds <= MAX_RETRY_WAIT).then(|| Duration::from_secs_f64(seconds))
        }
        _ => Some(backoff(attempt)),
    }
}

fn backoff(attempt: u32) -> Duration {
    let exponent = attempt.min(16) as i32;
    Duration::from_secs_f64((0.5 * 2f64.powi(exponent)).min(8.0))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_repeated_query_parameters() {
        let query: Query = vec![
            ("sort", "price desc".to_owned()),
            ("sort", "name asc".to_owned()),
            ("where", "name = 'Chef''s'".to_owned()),
            ("available", "true".to_owned()),
        ];
        assert_eq!(
            encode_query(&query),
            "sort=price%20desc&sort=name%20asc&where=name%20%3D%20%27Chef%27%27s%27&available=true"
        );
    }

    #[test]
    fn backoff_doubles_up_to_eight_seconds() {
        let waits: Vec<f64> = (0..6).map(|attempt| backoff(attempt).as_secs_f64()).collect();
        assert_eq!(waits, vec![0.5, 1.0, 2.0, 4.0, 8.0, 8.0]);
    }

    #[test]
    fn retry_after_rules() {
        let with = |value: &str| BTreeMap::from([("retry-after".to_owned(), value.to_owned())]);
        assert_eq!(retry_wait(429, &with("3"), 0), Some(Duration::from_secs(3)));
        assert_eq!(retry_wait(429, &with("0"), 0), Some(Duration::ZERO));
        assert_eq!(retry_wait(503, &with("soon"), 1), Some(Duration::from_secs(1)));
        assert_eq!(retry_wait(429, &with("120"), 0), None);
        assert_eq!(retry_wait(500, &with("1"), 0), None);
        assert_eq!(retry_wait(504, &BTreeMap::new(), 2), Some(Duration::from_secs(2)));
    }
}
