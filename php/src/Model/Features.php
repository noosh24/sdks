<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Features extends Model
{
    public readonly ?bool $loyalty;
    public readonly ?bool $inventory;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->loyalty = self::bool($data, 'loyalty');
        $model->inventory = self::bool($data, 'inventory');

        return $model;
    }
}
