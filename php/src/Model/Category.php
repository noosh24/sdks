<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Category extends Model
{
    public ?string $name = null;
    public ?int $position = null;
    public ?int $products = null;
    public ?int $available = null;

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
