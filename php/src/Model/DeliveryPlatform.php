<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class DeliveryPlatform extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $ref = null;

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
