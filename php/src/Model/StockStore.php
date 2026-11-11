<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class StockStore extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?bool $isDefault;
    /** @var list<string>|null */
    public readonly ?array $stations;

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
