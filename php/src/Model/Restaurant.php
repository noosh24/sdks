<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Restaurant extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $slug;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->slug = self::string($data, 'slug');

        return $model;
    }
}
