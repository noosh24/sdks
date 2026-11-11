<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Ingredient extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $unit;
    public readonly ?float $stock;
    public readonly ?float $onOpenBills;
    public readonly ?float $available;
    public readonly ?string $state;
    public readonly ?float $lowStock;
    public readonly ?float $parStock;
    public readonly ?float $costPerUnit;
    public readonly ?float $value;
    public readonly ?bool $prepared;
    /** @var array<string, float>|null */
    public readonly ?array $byStore;
    public readonly ?\DateTimeImmutable $updatedAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->unit = self::string($data, 'unit');
        $model->stock = self::float($data, 'stock');
        $model->onOpenBills = self::float($data, 'onOpenBills');
        $model->available = self::float($data, 'available');
        $model->state = self::string($data, 'state');
        $model->lowStock = self::float($data, 'lowStock');
        $model->parStock = self::float($data, 'parStock');
        $model->costPerUnit = self::float($data, 'costPerUnit');
        $model->value = self::float($data, 'value');
        $model->prepared = self::bool($data, 'prepared');
        $model->byStore = self::floats($data, 'byStore');
        $model->updatedAt = self::dateTime($data, 'updatedAt');

        return $model;
    }
}
