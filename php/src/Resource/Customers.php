<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Customer;
use Noosh24\OpenApi\Page;

final class Customers extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Customer>
     */
    public function list(array $params = []): Page
    {
        return $this->fetchPage('/customers', $params, [Customer::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Customer>
     */
    public function iterate(array $params = []): \Generator
    {
        return $this->paginate('/customers', $params, [Customer::class, 'fromArray'], 100);
    }

    public function get(string $customerId): Customer
    {
        return $this->fetchOne('/customers/' . self::id($customerId), [], [Customer::class, 'fromArray']);
    }
}
