<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ProductTranslation extends Model
{
    public readonly ?string $name;
    public readonly ?string $description;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->name = self::string($data, 'name');
        $model->description = self::string($data, 'description');

        return $model;
    }
}
