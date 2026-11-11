<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Payment;
use Noosh24\OpenApi\Page;

final class Payments extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Payment>
     */
    public function list(array $params = []): Page
    {
        return $this->fetchPage('/payments', $params, [Payment::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Payment>
     */
    public function iterate(array $params = []): \Generator
    {
        return $this->paginate('/payments', $params, [Payment::class, 'fromArray'], 100);
    }

    public function get(string $paymentId): Payment
    {
        return $this->fetchOne('/payments/' . self::id($paymentId), [], [Payment::class, 'fromArray']);
    }

    /**
     * @return array<string, mixed>
     */
    public function zReport(string|\DateTimeInterface|null $date = null): array
    {
        $query = $date === null ? [] : ['date' => self::date($date)];
        $data = $this->client->request('GET', '/reports/z', $query)['data'];

        return is_array($data) ? $data : [];
    }
}
