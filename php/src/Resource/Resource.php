<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Client;
use Noosh24\OpenApi\Page;
use Noosh24\OpenApi\Where;

abstract class Resource
{
    private const LIST_KEYS = ['limit', 'offset', 'sort', 'where', 'expand'];

    protected Client $client;

    final public function __construct(Client $client)
    {
        $this->client = $client;
    }

    /**
     * @template T
     * @param array<string, mixed> $params
     * @param callable(array<string, mixed>): T $factory
     * @return Page<T>
     */
    protected function fetchPage(string $path, array $params, callable $factory): Page
    {
        $data = $this->client->request('GET', $path, self::listQuery($params))['data'];
        $items = [];
        foreach ($data['items'] ?? [] as $item) {
            if (is_array($item)) {
                $items[] = $factory($item);
            }
        }

        return new Page(
            $items,
            (int) ($data['total'] ?? count($items)),
            (int) ($data['limit'] ?? ($params['limit'] ?? count($items))),
            (int) ($data['offset'] ?? ($params['offset'] ?? 0))
        );
    }

    /**
     * @template T
     * @param array<string, mixed> $params
     * @param callable(array<string, mixed>): T $factory
     * @return \Generator<int, T>
     */
    protected function paginate(string $path, array $params, callable $factory, int $pageSize): \Generator
    {
        $params['limit'] = $params['limit'] ?? $pageSize;
        $params['offset'] = $params['offset'] ?? 0;
        while (true) {
            $page = $this->fetchPage($path, $params, $factory);
            foreach ($page->items as $item) {
                yield $item;
            }
            if (!$page->hasMore()) {
                return;
            }
            $params['offset'] = $page->nextOffset();
        }
    }

    /**
     * @template T
     * @param callable(array<string, mixed>): T $factory
     * @return list<T>
     */
    protected function fetchAll(string $path, callable $factory): array
    {
        $data = $this->client->request('GET', $path)['data'];
        $items = [];
        foreach ($data['items'] ?? [] as $item) {
            if (is_array($item)) {
                $items[] = $factory($item);
            }
        }

        return $items;
    }

    /**
     * @template T
     * @param array<string, mixed> $query
     * @param callable(array<string, mixed>): T $factory
     * @return T
     */
    protected function fetchOne(string $path, array $query, callable $factory)
    {
        $data = $this->client->request('GET', $path, $query)['data'];

        return $factory(is_array($data) ? $data : []);
    }

    protected static function id(string $id): string
    {
        if (trim($id) === '') {
            throw new \InvalidArgumentException('An id is required');
        }

        return rawurlencode($id);
    }

    /**
     * @param string|list<string>|null $expand
     * @return list<string>
     */
    protected static function expand($expand): array
    {
        if ($expand === null || $expand === '' || $expand === []) {
            return [];
        }

        return is_array($expand) ? array_values($expand) : [$expand];
    }

    /**
     * @param string|\DateTimeInterface $date
     */
    protected static function date($date): string
    {
        return $date instanceof \DateTimeInterface ? $date->format('Y-m-d') : $date;
    }

    /**
     * @param array<string, mixed> $params
     * @return array<string, mixed>
     */
    private static function listQuery(array $params): array
    {
        $unknown = array_diff(array_keys($params), self::LIST_KEYS);
        if ($unknown !== []) {
            throw new \InvalidArgumentException('Unknown list parameter: ' . implode(', ', $unknown));
        }
        $query = [];
        if (isset($params['limit'])) {
            $query['limit'] = (int) $params['limit'];
        }
        if (isset($params['offset'])) {
            $query['offset'] = (int) $params['offset'];
        }
        if (isset($params['sort']) && $params['sort'] !== '' && $params['sort'] !== []) {
            $query['sort'] = is_array($params['sort']) ? array_values($params['sort']) : [$params['sort']];
        }
        if (isset($params['where'])) {
            $where = $params['where'] instanceof Where ? $params['where']->toString() : (string) $params['where'];
            if ($where !== '') {
                $query['where'] = $where;
            }
        }
        $expand = self::expand($params['expand'] ?? null);
        if ($expand !== []) {
            $query['expand'] = $expand;
        }

        return $query;
    }
}
