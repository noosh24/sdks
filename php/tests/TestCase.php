<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Client;

abstract class TestCase extends \PHPUnit\Framework\TestCase
{
    protected MockTransport $http;

    /** @var list<float> */
    protected array $sleeps = [];

    /**
     * @param array<string, mixed> $options
     */
    protected function client(array $options = []): Client
    {
        $this->http = new MockTransport();
        $this->sleeps = [];

        return new Client('nsk_test_123', $options + [
            'transport' => $this->http,
            'sleep' => function (float $seconds): void {
                $this->sleeps[] = $seconds;
            },
        ]);
    }

    /**
     * @param list<array<string, mixed>> $items
     * @return array<string, mixed>
     */
    protected static function page(array $items, int $total, int $limit = 20, int $offset = 0): array
    {
        return ['data' => ['items' => $items, 'total' => $total, 'limit' => $limit, 'offset' => $offset]];
    }
}
