<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

use Noosh24\OpenApi\Model\Reservation;

final readonly class CreateReservationResult
{
    public function __construct(
        public Reservation $reservation,
        public bool $created,
    ) {
    }
}
