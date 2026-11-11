<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Ingredient;
use Noosh24\OpenApi\Model\StockMove;
use Noosh24\OpenApi\Model\StockStore;
use Noosh24\OpenApi\Page;

final class Stock extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Ingredient>
     */
    public function listIngredients(array $params = []): Page
    {
        return $this->fetchPage('/stock/ingredients', $params, [Ingredient::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Ingredient>
     */
    public function iterateIngredients(array $params = []): \Generator
    {
        return $this->paginate('/stock/ingredients', $params, [Ingredient::class, 'fromArray'], 100);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<StockMove>
     */
    public function listMoves(array $params = []): Page
    {
        return $this->fetchPage('/stock/moves', $params, [StockMove::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, StockMove>
     */
    public function iterateMoves(array $params = []): \Generator
    {
        return $this->paginate('/stock/moves', $params, [StockMove::class, 'fromArray'], 100);
    }

    /**
     * @return list<StockStore>
     */
    public function listStores(): array
    {
        return $this->fetchAll('/stock/stores', [StockStore::class, 'fromArray']);
    }
}
