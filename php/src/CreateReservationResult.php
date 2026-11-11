<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

use Noosh24\OpenApi\Model\Reservation;

final class CreateReservationResult
{
    public Reservation $reservation;

    public bool $created;

    public function __construct(Reservation $reservation, bool $created)
    {
        $this->reservation = $reservation;
        $this->created = $created;
    }
}
