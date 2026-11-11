<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Features extends Model
{
    public ?bool $loyalty = null;
    public ?bool $inventory = null;

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
