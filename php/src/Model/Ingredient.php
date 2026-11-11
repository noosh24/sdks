<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Ingredient extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $unit = null;
    public ?float $stock = null;
    public ?float $onOpenBills = null;
    public ?float $available = null;
    public ?string $state = null;
    public ?float $lowStock = null;
    public ?float $parStock = null;
    public ?float $costPerUnit = null;
    public ?float $value = null;
    public ?bool $prepared = null;
    /** @var array<string, float>|null */
    public ?array $byStore = null;
    public ?\DateTimeImmutable $updatedAt = null;

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
