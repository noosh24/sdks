#![forbid(unsafe_code)]

macro_rules! string_enum {
    ($name:ident { $($variant:ident => $value:literal,)+ }) => {
        #[derive(Debug, Clone, PartialEq, Eq, Hash)]
        #[non_exhaustive]
        pub enum $name {
            $($variant,)+
            Unknown(String),
        }

        impl $name {
            pub fn as_str(&self) -> &str {
                match self {
                    $(Self::$variant => $value,)+
                    Self::Unknown(value) => value,
                }
            }
        }

        impl From<&str> for $name {
            fn from(value: &str) -> Self {
                match value {
                    $($value => Self::$variant,)+
                    other => Self::Unknown(other.to_owned()),
                }
            }
        }

        impl From<String> for $name {
            fn from(value: String) -> Self {
                match value.as_str() {
                    $($value => Self::$variant,)+
                    _ => Self::Unknown(value),
                }
            }
        }

        impl std::str::FromStr for $name {
            type Err = std::convert::Infallible;

            fn from_str(value: &str) -> Result<Self, Self::Err> {
                Ok(Self::from(value))
            }
        }

        impl std::fmt::Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                f.write_str(self.as_str())
            }
        }

        impl serde::Serialize for $name {
            fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
                serializer.serialize_str(self.as_str())
            }
        }

        impl<'de> serde::Deserialize<'de> for $name {
            fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
                <String as serde::Deserialize>::deserialize(deserializer).map(Self::from)
            }
        }
    };
}

mod client;
mod de;
mod error;
pub mod models;
mod pagination;
mod params;
mod resources;
mod transport;
mod where_clause;

pub use client::{Client, ClientBuilder, DEFAULT_BASE_URL, VERSION};
pub use error::{ApiError, BoxError, Error, ErrorCode, ErrorKind, Result};
pub use models::*;
pub use pagination::Page;
pub use params::{CreateReservationResult, Filter, ListParams, NewReservation, PreOrderLine};
pub use resources::{Customers, Loyalty, Menu, Orders, Payments, Reservations, Reviews, Stock, Tables};
pub use transport::{BoxFuture, HttpRequest, HttpResponse, ReqwestTransport, Transport, TransportError};
pub use where_clause::{Where, WhereValue, literal};

pub use chrono;
