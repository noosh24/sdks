<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class StopListItem extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $category = null;
    public ?float $price = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->category = self::string($data, 'category');
        $model->price = self::float($data, 'price');

        return $model;
    }
}
