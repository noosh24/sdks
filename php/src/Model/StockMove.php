<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class StockMove extends Model
{
    public ?string $id = null;
    public ?string $ingredientId = null;
    public ?float $qty = null;
    public ?string $reason = null;
    public ?string $orderId = null;
    public ?string $invoiceId = null;
    public ?string $storeId = null;
    public ?string $note = null;
    public ?\DateTimeImmutable $createdAt = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->ingredientId = self::string($data, 'ingredientId');
        $model->qty = self::float($data, 'qty');
        $model->reason = self::string($data, 'reason');
        $model->orderId = self::string($data, 'orderId');
        $model->invoiceId = self::string($data, 'invoiceId');
        $model->storeId = self::string($data, 'storeId');
        $model->note = self::string($data, 'note');
        $model->createdAt = self::dateTime($data, 'createdAt');

        return $model;
    }
}
