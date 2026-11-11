<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Review;
use Noosh24\OpenApi\Page;

final class Reviews extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Review>
     */
    public function list(array $params = []): Page
    {
        return $this->fetchPage('/reviews', $params, [Review::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Review>
     */
    public function iterate(array $params = []): \Generator
    {
        return $this->paginate('/reviews', $params, [Review::class, 'fromArray'], 100);
    }
}
