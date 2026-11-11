<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Bill extends Model
{
    public readonly ?string $id;
    public readonly ?string $tableId;
    public readonly ?string $status;
    public readonly ?int $guests;
    public readonly ?string $waiter;
    public readonly ?string $customerId;
    public readonly ?string $reservationId;
    /** @var list<string>|null */
    public readonly ?array $orderIds;
    public readonly ?float $subtotal;
    public readonly ?float $discountPercent;
    public readonly ?float $billDiscount;
    public readonly ?float $serviceFeePercent;
    public readonly ?float $serviceFee;
    public readonly ?float $total;
    public readonly ?float $paid;
    public readonly ?float $remaining;
    public readonly ?\DateTimeImmutable $openedAt;
    public readonly ?\DateTimeImmutable $closedAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->tableId = self::string($data, 'tableId');
        $model->status = self::string($data, 'status');
        $model->guests = self::int($data, 'guests');
        $model->waiter = self::string($data, 'waiter');
        $model->customerId = self::string($data, 'customerId');
        $model->reservationId = self::string($data, 'reservationId');
        $model->orderIds = self::strings($data, 'orderIds');
        $model->subtotal = self::float($data, 'subtotal');
        $model->discountPercent = self::float($data, 'discountPercent');
        $model->billDiscount = self::float($data, 'billDiscount');
        $model->serviceFeePercent = self::float($data, 'serviceFeePercent');
        $model->serviceFee = self::float($data, 'serviceFee');
        $model->total = self::float($data, 'total');
        $model->paid = self::float($data, 'paid');
        $model->remaining = self::float($data, 'remaining');
        $model->openedAt = self::dateTime($data, 'openedAt');
        $model->closedAt = self::dateTime($data, 'closedAt');

        return $model;
    }
}
