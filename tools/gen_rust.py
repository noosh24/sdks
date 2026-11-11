import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_models import ENUMS, MODELS, ROOT, parse

KEYWORDS = {"ref": "reference", "type": "kind", "box": "boxed", "match": "matched", "move": "moved", "self": "this"}


def snake(name):
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def camel(name):
    head, *rest = name.split("_")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def pascal(value):
    return "".join(part[:1].upper() + part[1:] for part in re.split(r"[_\-\s]+", value) if part)


def enum_name(model, field):
    return model + field[0].upper() + field[1:]


def rust_type(model, fname, kind):
    if (model, fname) in ENUMS:
        return "Option<%s>" % enum_name(model, fname), "de::enumeration"
    if kind == "s":
        return "Option<String>", "de::string"
    if kind == "i":
        return "Option<i64>", "de::int"
    if kind == "f":
        return "Option<f64>", "de::float"
    if kind == "b":
        return "Option<bool>", "de::boolean"
    if kind == "t":
        return "Option<DateTime<Utc>>", "de::datetime"
    if kind == "[s]":
        return "Vec<String>", "de::strings"
    if kind == "{f}":
        return "HashMap<String, f64>", "de::floats"
    if kind.startswith("["):
        return "Vec<%s>" % kind[1:-1], "de::models"
    if kind.startswith("{"):
        return "HashMap<String, %s>" % kind[1:-1], "de::model_map"
    return "Option<%s>" % kind, "de::model"


def skip_if(kind):
    if kind.startswith("["):
        return "Vec::is_empty"
    if kind.startswith("{"):
        return "HashMap::is_empty"
    return "Option::is_none"


def gen():
    lines = [
        "use std::collections::HashMap;",
        "",
        "use chrono::{DateTime, Utc};",
        "use serde::{Deserialize, Serialize};",
        "use serde_json::{Map, Value};",
        "",
        "use crate::de;",
        "",
    ]
    for (model, fname), values in ENUMS.items():
        lines.append("string_enum! {")
        lines.append("    %s {" % enum_name(model, fname))
        for value in values:
            lines.append('        %s => "%s",' % (pascal(value), value))
        lines.append("    }")
        lines.append("}")
        lines.append("")
    for name, _, spec in MODELS:
        lines += [
            "#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]",
            '#[serde(rename_all = "camelCase")]',
            "#[non_exhaustive]",
            "pub struct %s {" % name,
        ]
        for fname, kind, _, _ in parse(spec):
            field = snake(fname)
            rename = ""
            if field in KEYWORDS:
                field = KEYWORDS[field]
                rename = 'rename = "%s", ' % fname
            elif camel(field) != fname:
                rename = 'rename = "%s", ' % fname
            ty, reader = rust_type(name, fname, kind)
            lines.append(
                '    #[serde(%sdefault, deserialize_with = "%s", skip_serializing_if = "%s")]' % (rename, reader, skip_if(kind))
            )
            lines.append("    pub %s: %s," % (field, ty))
        lines += [
            "    #[serde(flatten)]",
            "    pub extra: Map<String, Value>,",
            "}",
            "",
        ]
    lines.append("pub type ZReport = Map<String, Value>;")
    path = os.path.join(ROOT, "rust", "src", "models.rs")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
    try:
        subprocess.run(["rustfmt", "--edition", "2024", path], check=False)
    except FileNotFoundError:
        pass


if __name__ == "__main__":
    gen()
