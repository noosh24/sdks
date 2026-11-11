<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Category extends Model
{
    public readonly ?string $name;
    public readonly ?int $position;
    public readonly ?int $products;
    public readonly ?int $available;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->name = self::string($data, 'name');
        $model->position = self::int($data, 'position');
        $model->products = self::int($data, 'products');
        $model->available = self::int($data, 'available');

        return $model;
    }
}
