<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class AvailableTable extends Model
{
    public readonly ?string $id;
    public readonly ?string $label;
    public readonly ?string $hallId;
    public readonly ?string $zone;
    public readonly ?int $seats;
    public readonly ?bool $free;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->label = self::string($data, 'label');
        $model->hallId = self::string($data, 'hallId');
        $model->zone = self::string($data, 'zone');
        $model->seats = self::int($data, 'seats');
        $model->free = self::bool($data, 'free');

        return $model;
    }
}
