<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class StockStore extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?bool $isDefault = null;
    /** @var list<string>|null */
    public ?array $stations = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->isDefault = self::bool($data, 'isDefault');
        $model->stations = self::strings($data, 'stations');

        return $model;
    }
}
