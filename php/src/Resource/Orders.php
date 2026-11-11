<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Bill;
use Noosh24\OpenApi\Model\Order;
use Noosh24\OpenApi\Page;

final class Orders extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Order>
     */
    public function list(array $params = []): Page
    {
        return $this->fetchPage('/orders', $params, [Order::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Order>
     */
    public function iterate(array $params = []): \Generator
    {
        return $this->paginate('/orders', $params, [Order::class, 'fromArray'], 100);
    }

    public function get(string $orderId): Order
    {
        return $this->fetchOne('/orders/' . self::id($orderId), [], [Order::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Bill>
     */
    public function listBills(array $params = []): Page
    {
        return $this->fetchPage('/bills', $params, [Bill::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Bill>
     */
    public function iterateBills(array $params = []): \Generator
    {
        return $this->paginate('/bills', $params, [Bill::class, 'fromArray'], 50);
    }

    public function getBill(string $billId): Bill
    {
        return $this->fetchOne('/bills/' . self::id($billId), [], [Bill::class, 'fromArray']);
    }
}
