<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\CreateReservationResult;
use Noosh24\OpenApi\Model\Reservation;
use Noosh24\OpenApi\Model\TableAvailability;
use Noosh24\OpenApi\Page;

final class Reservations extends Resource
{
    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<Reservation>
     */
    public function list(array $params = []): Page
    {
        return $this->fetchPage('/reservations', $params, [Reservation::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, Reservation>
     */
    public function iterate(array $params = []): \Generator
    {
        return $this->paginate('/reservations', $params, [Reservation::class, 'fromArray'], 100);
    }

    public function get(string $reservationId): Reservation
    {
        return $this->fetchOne('/reservations/' . self::id($reservationId), [], [Reservation::class, 'fromArray']);
    }

    /**
     * @param string|\DateTimeInterface $date
     */
    public function availability($date, string $time, ?int $guests = null): TableAvailability
    {
        $query = ['date' => self::date($date), 'time' => $time];
        if ($guests !== null) {
            $query['guests'] = $guests;
        }

        return $this->fetchOne('/reservations/availability', $query, [TableAvailability::class, 'fromArray']);
    }

    /**
     * @param array{date: string|\DateTimeInterface, time: string, guests: int, guestName: string, phone: string, email?: string, tableId?: string, zone?: string, specialRequest?: string, allergyNote?: string, birthday?: bool, childChair?: bool, preOrder?: list<array{itemId: string, qty: int, note?: string}>, externalRef?: string} $reservation
     */
    public function create(array $reservation): CreateReservationResult
    {
        if (isset($reservation['date'])) {
            $reservation['date'] = self::date($reservation['date']);
        }
        $idempotent = isset($reservation['externalRef']) && trim((string) $reservation['externalRef']) !== '';
        $response = $this->client->request('POST', '/reservations', [], $reservation, $idempotent);
        $data = is_array($response['data']) ? $response['data'] : [];

        return new CreateReservationResult(Reservation::fromArray($data), $response['status'] === 201);
    }

    public function cancel(string $reservationId): Reservation
    {
        $response = $this->client->request('POST', '/reservations/' . self::id($reservationId) . '/cancel');

        return Reservation::fromArray(is_array($response['data']) ? $response['data'] : []);
    }
}
