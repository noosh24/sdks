<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReservationTable extends Model
{
    public readonly ?string $id;
    public readonly ?string $label;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->label = self::string($data, 'label');

        return $model;
    }
}
