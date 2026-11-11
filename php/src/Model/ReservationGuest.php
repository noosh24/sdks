<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReservationGuest extends Model
{
    public readonly ?string $name;
    public readonly ?string $phone;
    public readonly ?string $email;

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
