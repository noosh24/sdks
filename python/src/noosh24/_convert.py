from __future__ import annotations

import re
from datetime import datetime
from typing import Any, Callable, Dict, List, Mapping, Optional, TypeVar

T = TypeVar("T")

_FRACTION = re.compile(r"\.(\d+)")


def _str(value: Any) -> Optional[str]:
    if value is None or isinstance(value, (dict, list)):
        return None
    return str(value)


def _int(value: Any) -> Optional[int]:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return int(value)


def _float(value: Any) -> Optional[float]:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def _bool(value: Any) -> Optional[bool]:
    if value is None or isinstance(value, (dict, list)):
        return None
    return bool(value)


def _datetime(value: Any) -> Optional[datetime]:
    if not isinstance(value, str) or value == "":
        return None
    text = value.strip()
    if text.endswith(("Z", "z")):
        text = text[:-1] + "+00:00"
    text = _FRACTION.sub(lambda m: "." + (m.group(1) + "000000")[:6], text, count=1)
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def _strings(value: Any) -> List[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if item is not None and not isinstance(item, (dict, list))]


def _floats(value: Any) -> Dict[str, float]:
    if not isinstance(value, dict):
        return {}
    return {str(k): float(v) for k, v in value.items() if isinstance(v, (int, float)) and not isinstance(v, bool)}


def _object(value: Any, model: Any) -> Any:
    if not isinstance(value, Mapping):
        return None
    return model.from_dict(value)


def _list_of(value: Any, model: Any) -> List[Any]:
    if not isinstance(value, list):
        return []
    return [model.from_dict(item) for item in value if isinstance(item, Mapping)]


def _map_of(value: Any, model: Any) -> Dict[str, Any]:
    if not isinstance(value, Mapping):
        return {}
    return {str(k): model.from_dict(v) for k, v in value.items() if isinstance(v, Mapping)}


def build(factory: Callable[[Mapping[str, Any]], T], data: Any) -> T:
    return factory(data if isinstance(data, Mapping) else {})
