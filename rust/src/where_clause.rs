use chrono::{DateTime, FixedOffset, NaiveDate, TimeZone};

use crate::error::{Error, Result};

#[derive(Debug, Clone, PartialEq)]
#[non_exhaustive]
pub enum WhereValue {
    String(String),
    Int(i64),
    Float(f64),
    Bool(bool),
    Date(NaiveDate),
    DateTime(DateTime<FixedOffset>),
    Null,
}

impl From<&str> for WhereValue {
    fn from(value: &str) -> Self {
        Self::String(value.to_owned())
    }
}

impl From<String> for WhereValue {
    fn from(value: String) -> Self {
        Self::String(value)
    }
}

impl From<&String> for WhereValue {
    fn from(value: &String) -> Self {
        Self::String(value.clone())
    }
}

macro_rules! int_values {
    ($($ty:ty),+) => {
        $(
            impl From<$ty> for WhereValue {
                fn from(value: $ty) -> Self {
                    Self::Int(i64::from(value))
                }
            }
        )+
    };
}

int_values!(i8, i16, i32, i64, u8, u16, u32);

impl From<u64> for WhereValue {
    fn from(value: u64) -> Self {
        i64::try_from(value).map_or(Self::Float(value as f64), Self::Int)
    }
}

impl From<f64> for WhereValue {
    fn from(value: f64) -> Self {
        Self::Float(value)
    }
}

impl From<f32> for WhereValue {
    fn from(value: f32) -> Self {
        Self::Float(f64::from(value))
    }
}

impl From<bool> for WhereValue {
    fn from(value: bool) -> Self {
        Self::Bool(value)
    }
}

impl From<NaiveDate> for WhereValue {
    fn from(value: NaiveDate) -> Self {
        Self::Date(value)
    }
}

impl<Tz: TimeZone> From<DateTime<Tz>> for WhereValue {
    fn from(value: DateTime<Tz>) -> Self {
        Self::DateTime(value.fixed_offset())
    }
}

impl<T: Into<WhereValue>> From<Option<T>> for WhereValue {
    fn from(value: Option<T>) -> Self {
        value.map_or(Self::Null, Into::into)
    }
}

pub fn literal(value: &WhereValue) -> Result<String> {
    Ok(match value {
        WhereValue::Bool(flag) => flag.to_string(),
        WhereValue::Int(number) => number.to_string(),
        WhereValue::Float(number) => {
            if !number.is_finite() {
                return Err(Error::invalid("Numbers in where must be finite"));
            }
            if number.fract() == 0.0 && number.abs() < 9.0e15 {
                (*number as i64).to_string()
            } else {
                number.to_string()
            }
        }
        WhereValue::String(text) => format!("'{}'", text.replace('\'', "''")),
        WhereValue::Date(date) => format!("'{}'", date.format("%Y-%m-%d")),
        WhereValue::DateTime(moment) => format!("'{}'", moment.to_rfc3339()),
        WhereValue::Null => {
            return Err(Error::invalid(
                "where takes strings, numbers, booleans and dates, not null",
            ));
        }
    })
}

fn check_field(name: &str) -> Result<&str> {
    let mut chars = name.chars();
    let valid = chars.next().is_some_and(|first| first.is_ascii_alphabetic())
        && chars.all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '.');
    if valid {
        Ok(name)
    } else {
        Err(Error::invalid(format!("\"{name}\" is not a field name")))
    }
}

#[derive(Debug, Clone, Default)]
pub struct Where {
    conditions: Vec<String>,
    error: Option<String>,
}

impl Where {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn eq(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, "=", value.into())
    }

    pub fn ne(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, "!=", value.into())
    }

    pub fn gt(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, ">", value.into())
    }

    pub fn gte(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, ">=", value.into())
    }

    pub fn lt(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, "<", value.into())
    }

    pub fn lte(self, field: &str, value: impl Into<WhereValue>) -> Self {
        self.compare(field, "<=", value.into())
    }

    pub fn in_<I, V>(self, field: &str, values: I) -> Self
    where
        I: IntoIterator<Item = V>,
        V: Into<WhereValue>,
    {
        let values: Vec<WhereValue> = values.into_iter().map(Into::into).collect();
        self.push(|| {
            let field = check_field(field)?;
            if values.is_empty() {
                return Err(Error::invalid("in_() needs at least one value"));
            }
            let literals = values.iter().map(literal).collect::<Result<Vec<_>>>()?;
            Ok(format!("{field} in ({})", literals.join(", ")))
        })
    }

    pub fn is_empty(&self) -> bool {
        self.conditions.is_empty() && self.error.is_none()
    }

    pub fn build(&self) -> Result<String> {
        match &self.error {
            Some(message) => Err(Error::invalid(message.clone())),
            None => Ok(self.conditions.join(" AND ")),
        }
    }

    fn compare(self, field: &str, operator: &str, value: WhereValue) -> Self {
        self.push(|| Ok(format!("{} {operator} {}", check_field(field)?, literal(&value)?)))
    }

    fn push(mut self, condition: impl FnOnce() -> Result<String>) -> Self {
        if self.error.is_none() {
            match condition() {
                Ok(text) => self.conditions.push(text),
                Err(error) => self.error = Some(error.to_string()),
            }
        }
        self
    }
}
