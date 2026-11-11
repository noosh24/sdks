<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class PaymentPlatform extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');

        return $model;
    }
}
