<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class StockMove extends Model
{
    public readonly ?string $id;
    public readonly ?string $ingredientId;
    public readonly ?float $qty;
    public readonly ?string $reason;
    public readonly ?string $orderId;
    public readonly ?string $invoiceId;
    public readonly ?string $storeId;
    public readonly ?string $note;
    public readonly ?\DateTimeImmutable $createdAt;

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
