use std::collections::BTreeMap;

use serde_json::Value;

pub type BoxError = Box<dyn std::error::Error + Send + Sync + 'static>;

pub type Result<T, E = Error> = std::result::Result<T, E>;

string_enum! {
    ErrorCode {
        ValidationError => "validation_error",
        NoApiKey => "no_api_key",
        InvalidApiKey => "invalid_api_key",
        InsufficientScope => "insufficient_scope",
        ModuleNotEnabled => "module_not_enabled",
        VenueSuspended => "venue_suspended",
        NotYourReservation => "not_your_reservation",
        NotFound => "not_found",
        TableNotFound => "table_not_found",
        TableTaken => "table_taken",
        CannotCancel => "cannot_cancel",
        OutsideHours => "outside_hours",
        InThePast => "in_the_past",
        TableTooSmall => "table_too_small",
        RateLimitExceeded => "rate_limit_exceeded",
        TemporarilyUnavailable => "temporarily_unavailable",
    }
}

impl ErrorCode {
    pub fn kind(&self) -> Option<ErrorKind> {
        Some(match self {
            Self::ValidationError => ErrorKind::Validation,
            Self::NoApiKey | Self::InvalidApiKey => ErrorKind::Authentication,
            Self::InsufficientScope | Self::ModuleNotEnabled | Self::VenueSuspended | Self::NotYourReservation => {
                ErrorKind::PermissionDenied
            }
            Self::NotFound | Self::TableNotFound => ErrorKind::NotFound,
            Self::TableTaken | Self::CannotCancel => ErrorKind::Conflict,
            Self::OutsideHours | Self::InThePast | Self::TableTooSmall => ErrorKind::Unprocessable,
            Self::RateLimitExceeded => ErrorKind::RateLimit,
            Self::TemporarilyUnavailable => ErrorKind::Server,
            Self::Unknown(_) => return None,
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[non_exhaustive]
pub enum ErrorKind {
    Validation,
    Authentication,
    PermissionDenied,
    NotFound,
    Conflict,
    Unprocessable,
    RateLimit,
    Server,
    Other,
}

impl ErrorKind {
    pub fn from_status(status: u16) -> Self {
        match status {
            400 => Self::Validation,
            401 => Self::Authentication,
            403 => Self::PermissionDenied,
            404 => Self::NotFound,
            409 => Self::Conflict,
            422 => Self::Unprocessable,
            429 => Self::RateLimit,
            500.. => Self::Server,
            _ => Self::Other,
        }
    }
}

#[derive(Debug, Clone, PartialEq, thiserror::Error)]
#[error("{message}")]
#[non_exhaustive]
pub struct ApiError {
    pub status: u16,
    pub code: Option<ErrorCode>,
    pub message: String,
    pub headers: BTreeMap<String, String>,
    pub body: String,
}

macro_rules! code_predicates {
    ($($name:ident => $variant:ident,)+) => {
        impl ApiError {
            $(
                pub fn $name(&self) -> bool {
                    matches!(self.code, Some(ErrorCode::$variant))
                }
            )+
        }

        impl Error {
            $(
                pub fn $name(&self) -> bool {
                    self.api().is_some_and(ApiError::$name)
                }
            )+
        }
    };
}

macro_rules! kind_predicates {
    ($($name:ident => $kind:ident,)+) => {
        impl ApiError {
            $(
                pub fn $name(&self) -> bool {
                    self.kind() == ErrorKind::$kind
                }
            )+
        }

        impl Error {
            $(
                pub fn $name(&self) -> bool {
                    self.api().is_some_and(ApiError::$name)
                }
            )+
        }
    };
}

code_predicates! {
    is_no_api_key => NoApiKey,
    is_invalid_api_key => InvalidApiKey,
    is_insufficient_scope => InsufficientScope,
    is_module_not_enabled => ModuleNotEnabled,
    is_venue_suspended => VenueSuspended,
    is_not_your_reservation => NotYourReservation,
    is_table_not_found => TableNotFound,
    is_table_taken => TableTaken,
    is_cannot_cancel => CannotCancel,
    is_outside_hours => OutsideHours,
    is_in_the_past => InThePast,
    is_table_too_small => TableTooSmall,
    is_temporarily_unavailable => TemporarilyUnavailable,
}

kind_predicates! {
    is_validation => Validation,
    is_authentication => Authentication,
    is_permission_denied => PermissionDenied,
    is_not_found => NotFound,
    is_conflict => Conflict,
    is_unprocessable => Unprocessable,
    is_rate_limited => RateLimit,
    is_server_error => Server,
}

impl ApiError {
    pub fn new(
        status: u16,
        code: Option<ErrorCode>,
        message: impl Into<String>,
        headers: BTreeMap<String, String>,
        body: impl Into<String>,
    ) -> Self {
        Self {
            status,
            code,
            message: message.into(),
            headers: headers
                .into_iter()
                .map(|(name, value)| (name.to_ascii_lowercase(), value))
                .collect(),
            body: body.into(),
        }
    }

    pub fn from_response(status: u16, headers: BTreeMap<String, String>, body: impl Into<String>) -> Self {
        let body = body.into();
        let mut code = None;
        let mut message = String::new();
        if let Ok(Value::Object(parsed)) = serde_json::from_str::<Value>(&body) {
            if let Some(Value::String(value)) = parsed.get("error") {
                code = Some(value.clone());
            }
            if let Some(Value::String(value)) = parsed.get("message") {
                message = value.clone();
            }
        }
        if message.is_empty() {
            message = code.clone().unwrap_or_else(|| format!("HTTP {status}"));
        }
        Self::new(status, code.map(ErrorCode::from), message, headers, body)
    }

    pub fn kind(&self) -> ErrorKind {
        self.code
            .as_ref()
            .and_then(ErrorCode::kind)
            .unwrap_or_else(|| ErrorKind::from_status(self.status))
    }

    pub fn header(&self, name: &str) -> Option<&str> {
        self.headers.get(&name.to_ascii_lowercase()).map(String::as_str)
    }

    pub fn retry_after(&self) -> Option<u64> {
        let seconds = self.header("retry-after")?.trim().parse::<f64>().ok()?;
        seconds.is_finite().then(|| seconds.max(0.0) as u64)
    }
}

#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum Error {
    #[error(transparent)]
    Api(#[from] ApiError),
    #[error("{message}")]
    Connection {
        message: String,
        #[source]
        source: Option<BoxError>,
    },
    #[error("{message}")]
    Timeout {
        message: String,
        #[source]
        source: Option<BoxError>,
    },
    #[error("{0}")]
    InvalidArgument(String),
}

impl Error {
    pub(crate) fn invalid(message: impl Into<String>) -> Self {
        Self::InvalidArgument(message.into())
    }

    pub fn api(&self) -> Option<&ApiError> {
        match self {
            Self::Api(error) => Some(error),
            _ => None,
        }
    }

    pub fn status(&self) -> Option<u16> {
        self.api().map(|error| error.status)
    }

    pub fn code(&self) -> Option<&ErrorCode> {
        self.api().and_then(|error| error.code.as_ref())
    }

    pub fn kind(&self) -> Option<ErrorKind> {
        self.api().map(ApiError::kind)
    }

    pub fn retry_after(&self) -> Option<u64> {
        self.api().and_then(ApiError::retry_after)
    }

    pub fn is_connection(&self) -> bool {
        matches!(self, Self::Connection { .. } | Self::Timeout { .. })
    }

    pub fn is_timeout(&self) -> bool {
        matches!(self, Self::Timeout { .. })
    }

    pub fn is_invalid_argument(&self) -> bool {
        matches!(self, Self::InvalidArgument(_))
    }
}
