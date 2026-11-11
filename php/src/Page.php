<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

/**
 * @template T
 * @implements \IteratorAggregate<int, T>
 */
final class Page implements \IteratorAggregate, \Countable
{
    /** @var list<T> */
    public array $items;

    public int $total;

    public int $limit;

    public int $offset;

    /**
     * @param list<T> $items
     */
    public function __construct(array $items, int $total, int $limit, int $offset)
    {
        $this->items = $items;
        $this->total = $total;
        $this->limit = $limit;
        $this->offset = $offset;
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
