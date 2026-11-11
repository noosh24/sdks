use chrono::{NaiveDate, NaiveTime};
use serde::{Serialize, Serializer};

use crate::client::Query;
use crate::error::{Error, Result};
use crate::models::Reservation;
use crate::where_clause::Where;

#[derive(Debug, Clone)]
pub enum Filter {
    Raw(String),
    Where(Where),
}

impl Filter {
    pub fn build(&self) -> Result<String> {
        match self {
            Self::Raw(text) => Ok(text.clone()),
            Self::Where(builder) => builder.build(),
        }
    }
}

impl From<&str> for Filter {
    fn from(value: &str) -> Self {
        Self::Raw(value.to_owned())
    }
}

impl From<String> for Filter {
    fn from(value: String) -> Self {
        Self::Raw(value)
    }
}

impl From<Where> for Filter {
    fn from(value: Where) -> Self {
        Self::Where(value)
    }
}

#[derive(Debug, Clone, Default)]
pub struct ListParams {
    pub limit: Option<u64>,
    pub offset: Option<u64>,
    pub sort: Vec<String>,
    pub where_: Option<Filter>,
    pub expand: Vec<String>,
}

impl ListParams {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn limit(mut self, limit: u64) -> Self {
        self.limit = Some(limit);
        self
    }

    pub fn offset(mut self, offset: u64) -> Self {
        self.offset = Some(offset);
        self
    }

    pub fn sort(mut self, sort: impl Into<String>) -> Self {
        self.sort.push(sort.into());
        self
    }

    pub fn where_(mut self, filter: impl Into<Filter>) -> Self {
        self.where_ = Some(filter.into());
        self
    }

    pub fn expand(mut self, expand: impl Into<String>) -> Self {
        self.expand.push(expand.into());
        self
    }
}

#[derive(Debug, Clone)]
pub(crate) struct ListQuery {
    pub(crate) limit: Option<u64>,
    pub(crate) offset: Option<u64>,
    sort: Vec<String>,
    filter: Option<String>,
    pub(crate) expand: Vec<String>,
}

impl ListQuery {
    pub(crate) fn new(params: ListParams, allow_expand: bool) -> Result<Self> {
        let expand: Vec<String> = params.expand.into_iter().filter(|value| !value.is_empty()).collect();
        if !allow_expand && !expand.is_empty() {
            return Err(Error::invalid("expand is only supported on products"));
        }
        let filter = match params.where_ {
            Some(filter) => Some(filter.build()?).filter(|text| !text.is_empty()),
            None => None,
        };
        Ok(Self {
            limit: params.limit,
            offset: params.offset,
            sort: params.sort.into_iter().filter(|value| !value.is_empty()).collect(),
            filter,
            expand,
        })
    }

    pub(crate) fn pairs(&self) -> Query {
        let mut query: Query = Vec::new();
        if let Some(limit) = self.limit {
            query.push(("limit", limit.to_string()));
        }
        if let Some(offset) = self.offset {
            query.push(("offset", offset.to_string()));
        }
        query.extend(self.sort.iter().map(|value| ("sort", value.clone())));
        if let Some(filter) = &self.filter {
            query.push(("where", filter.clone()));
        }
        query.extend(self.expand.iter().map(|value| ("expand", value.clone())));
        query
    }
}

fn date<S: Serializer>(value: &NaiveDate, serializer: S) -> std::result::Result<S::Ok, S::Error> {
    serializer.collect_str(&value.format("%Y-%m-%d"))
}

fn time<S: Serializer>(value: &NaiveTime, serializer: S) -> std::result::Result<S::Ok, S::Error> {
    serializer.collect_str(&value.format("%H:%M"))
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct PreOrderLine {
    pub item_id: String,
    pub qty: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

impl PreOrderLine {
    pub fn new(item_id: impl Into<String>, qty: u32) -> Self {
        Self {
            item_id: item_id.into(),
            qty,
            note: None,
        }
    }

    pub fn note(mut self, note: impl Into<String>) -> Self {
        self.note = Some(note.into());
        self
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct NewReservation {
    #[serde(serialize_with = "date")]
    pub date: NaiveDate,
    #[serde(serialize_with = "time")]
    pub time: NaiveTime,
    pub guests: u32,
    pub guest_name: String,
    pub phone: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub table_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub zone: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub special_request: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allergy_note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub birthday: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub child_chair: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pre_order: Option<Vec<PreOrderLine>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external_ref: Option<String>,
}

impl NewReservation {
    pub fn new(
        date: NaiveDate,
        time: NaiveTime,
        guests: u32,
        guest_name: impl Into<String>,
        phone: impl Into<String>,
    ) -> Self {
        Self {
            date,
            time,
            guests,
            guest_name: guest_name.into(),
            phone: phone.into(),
            email: None,
            table_id: None,
            zone: None,
            special_request: None,
            allergy_note: None,
            birthday: None,
            child_chair: None,
            pre_order: None,
            external_ref: None,
        }
    }

    pub fn email(mut self, email: impl Into<String>) -> Self {
        self.email = Some(email.into());
        self
    }

    pub fn table_id(mut self, table_id: impl Into<String>) -> Self {
        self.table_id = Some(table_id.into());
        self
    }

    pub fn zone(mut self, zone: impl Into<String>) -> Self {
        self.zone = Some(zone.into());
        self
    }

    pub fn special_request(mut self, special_request: impl Into<String>) -> Self {
        self.special_request = Some(special_request.into());
        self
    }

    pub fn allergy_note(mut self, allergy_note: impl Into<String>) -> Self {
        self.allergy_note = Some(allergy_note.into());
        self
    }

    pub fn birthday(mut self, birthday: bool) -> Self {
        self.birthday = Some(birthday);
        self
    }

    pub fn child_chair(mut self, child_chair: bool) -> Self {
        self.child_chair = Some(child_chair);
        self
    }

    pub fn pre_order(mut self, line: PreOrderLine) -> Self {
        self.pre_order.get_or_insert_with(Vec::new).push(line);
        self
    }

    pub fn external_ref(mut self, external_ref: impl Into<String>) -> Self {
        self.external_ref = Some(external_ref.into());
        self
    }

    pub(crate) fn is_idempotent(&self) -> bool {
        self.external_ref
            .as_deref()
            .is_some_and(|value| !value.trim().is_empty())
    }
}

#[derive(Debug, Clone, PartialEq)]
#[non_exhaustive]
pub struct CreateReservationResult {
    pub reservation: Reservation,
    pub created: bool,
}
