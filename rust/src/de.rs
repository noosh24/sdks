use std::collections::HashMap;

use chrono::{DateTime, Utc};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Deserializer};
use serde_json::Value;

pub(crate) fn scalar_string(value: Value) -> Option<String> {
    match value {
        Value::String(text) => Some(text),
        Value::Number(number) => Some(number.to_string()),
        Value::Bool(flag) => Some(flag.to_string()),
        _ => None,
    }
}

pub(crate) fn number_i64(value: &Value) -> Option<i64> {
    match value {
        Value::Number(number) => number.as_i64().or_else(|| number.as_f64().map(|f| f as i64)),
        _ => None,
    }
}

pub(crate) fn number_f64(value: &Value) -> Option<f64> {
    match value {
        Value::Number(number) => number.as_f64(),
        _ => None,
    }
}

pub(crate) fn parse_datetime(text: &str) -> Option<DateTime<Utc>> {
    DateTime::parse_from_rfc3339(text.trim())
        .ok()
        .map(|value| value.with_timezone(&Utc))
}

pub(crate) fn from_object<T: DeserializeOwned>(value: Value) -> Option<T> {
    match value {
        Value::Object(_) => T::deserialize(value).ok(),
        _ => None,
    }
}

pub(crate) fn string<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<String>, D::Error> {
    Ok(scalar_string(Value::deserialize(deserializer)?))
}

pub(crate) fn int<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<i64>, D::Error> {
    Ok(number_i64(&Value::deserialize(deserializer)?))
}

pub(crate) fn float<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<f64>, D::Error> {
    Ok(number_f64(&Value::deserialize(deserializer)?))
}

pub(crate) fn boolean<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<bool>, D::Error> {
    Ok(match Value::deserialize(deserializer)? {
        Value::Bool(flag) => Some(flag),
        Value::Number(number) => Some(number.as_f64().is_some_and(|n| n != 0.0)),
        Value::String(text) => Some(!text.is_empty()),
        _ => None,
    })
}

pub(crate) fn datetime<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<DateTime<Utc>>, D::Error> {
    Ok(match Value::deserialize(deserializer)? {
        Value::String(text) => parse_datetime(&text),
        _ => None,
    })
}

pub(crate) fn enumeration<'de, D, T>(deserializer: D) -> Result<Option<T>, D::Error>
where
    D: Deserializer<'de>,
    T: From<String>,
{
    Ok(match Value::deserialize(deserializer)? {
        Value::String(text) => Some(T::from(text)),
        _ => None,
    })
}

pub(crate) fn strings<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Vec<String>, D::Error> {
    Ok(match Value::deserialize(deserializer)? {
        Value::Array(items) => items.into_iter().filter_map(scalar_string).collect(),
        _ => Vec::new(),
    })
}

pub(crate) fn floats<'de, D: Deserializer<'de>>(deserializer: D) -> Result<HashMap<String, f64>, D::Error> {
    Ok(match Value::deserialize(deserializer)? {
        Value::Object(entries) => entries
            .into_iter()
            .filter_map(|(key, value)| number_f64(&value).map(|number| (key, number)))
            .collect(),
        _ => HashMap::new(),
    })
}

pub(crate) fn model<'de, D, T>(deserializer: D) -> Result<Option<T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    Ok(from_object(Value::deserialize(deserializer)?))
}

pub(crate) fn models<'de, D, T>(deserializer: D) -> Result<Vec<T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    Ok(match Value::deserialize(deserializer)? {
        Value::Array(items) => items.into_iter().filter_map(from_object).collect(),
        _ => Vec::new(),
    })
}

pub(crate) fn model_map<'de, D, T>(deserializer: D) -> Result<HashMap<String, T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    Ok(match Value::deserialize(deserializer)? {
        Value::Object(entries) => entries
            .into_iter()
            .filter_map(|(key, value)| from_object(value).map(|model| (key, model)))
            .collect(),
        _ => HashMap::new(),
    })
}
