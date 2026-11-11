<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

/**
 * @template T
 * @implements \IteratorAggregate<int, T>
 */
final readonly class Page implements \IteratorAggregate, \Countable
{
    /**
     * @param list<T> $items
     */
    public function __construct(
        public array $items,
        public int $total,
        public int $limit,
        public int $offset,
    ) {
    }

    public function hasMore(): bool
    {
        return $this->items !== [] && $this->offset + count($this->items) < $this->total;
    }

    public function nextOffset(): int
    {
        return $this->offset + count($this->items);
    }

    /**
     * @return \ArrayIterator<int, T>
     */
    public function getIterator(): \ArrayIterator
    {
        return new \ArrayIterator($this->items);
    }

    public function count(): int
    {
        return count($this->items);
    }
}
