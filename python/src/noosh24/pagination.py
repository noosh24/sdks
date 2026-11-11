from __future__ import annotations

from dataclasses import dataclass, field
from typing import Generic, Iterator, List, TypeVar

T = TypeVar("T")

__all__ = ["Page"]


@dataclass(frozen=True)
class Page(Generic[T]):
    items: List[T] = field(default_factory=list)
    total: int = 0
    limit: int = 0
    offset: int = 0

    @property
    def has_more(self) -> bool:
        return bool(self.items) and self.offset + len(self.items) < self.total

    @property
    def next_offset(self) -> int:
        return self.offset + len(self.items)

    def __iter__(self) -> Iterator[T]:
        return iter(self.items)

    def __len__(self) -> int:
        return len(self.items)
