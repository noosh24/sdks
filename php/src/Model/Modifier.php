<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Modifier extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?float $priceDelta;
    public readonly ?int $position;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->priceDelta = self::float($data, 'priceDelta');
        $model->position = self::int($data, 'position');

        return $model;
    }
}
