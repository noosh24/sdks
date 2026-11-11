<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReservationGuest extends Model
{
    public ?string $name = null;
    public ?string $phone = null;
    public ?string $email = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->name = self::string($data, 'name');
        $model->phone = self::string($data, 'phone');
        $model->email = self::string($data, 'email');

        return $model;
    }
}
