<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Bill extends Model
{
    public ?string $id = null;
    public ?string $tableId = null;
    public ?string $status = null;
    public ?int $guests = null;
    public ?string $waiter = null;
    public ?string $customerId = null;
    public ?string $reservationId = null;
    /** @var list<string>|null */
    public ?array $orderIds = null;
    public ?float $subtotal = null;
    public ?float $discountPercent = null;
    public ?float $billDiscount = null;
    public ?float $serviceFeePercent = null;
    public ?float $serviceFee = null;
    public ?float $total = null;
    public ?float $paid = null;
    public ?float $remaining = null;
    public ?\DateTimeImmutable $openedAt = null;
    public ?\DateTimeImmutable $closedAt = null;

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
