<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Category;
use Noosh24\OpenApi\Model\Product;
use Noosh24\OpenApi\Model\StopListItem;
use Noosh24\OpenApi\Page;

final class Menu extends Resource
{
    /**
     * @return list<Category>
     */
    public function listCategories(): array
    {
        return $this->fetchAll('/menu/categories', [Category::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where, expand?: string|list<string>} $params
     * @return Page<Product>
     */
    public function listProducts(array $params = []): Page
    {
        return $this->fetchPage('/menu/products', $params, [Product::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where, expand?: string|list<string>} $params
     * @return \Generator<int, Product>
     */
    public function iterateProducts(array $params = []): \Generator
    {
        $pageSize = self::expand($params['expand'] ?? null) === [] ? 100 : 50;

        return $this->paginate('/menu/products', $params, [Product::class, 'fromArray'], $pageSize);
    }

    /**
     * @param string|list<string>|null $expand
     */
    public function getProduct(string $productId, string|array|null $expand = null): Product
    {
        $query = [];
        $expand = self::expand($expand);
        if ($expand !== []) {
            $query['expand'] = $expand;
        }

        return $this->fetchOne('/menu/products/' . self::id($productId), $query, [Product::class, 'fromArray']);
    }

    /**
     * @return list<StopListItem>
     */
    public function getStopList(): array
    {
        return $this->fetchAll('/menu/stop-list', [StopListItem::class, 'fromArray']);
    }
}
