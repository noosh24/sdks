<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class DeliveryPlatform extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $ref;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->ref = self::string($data, 'ref');

        return $model;
    }
}
