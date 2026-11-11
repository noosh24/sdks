<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Order extends Model
{
    public readonly ?string $id;
    public readonly ?string $number;
    public readonly ?int $dailyNumber;
    public readonly ?string $kind;
    public readonly ?string $orderType;
    public readonly ?string $status;
    public readonly ?string $tableId;
    public readonly ?string $billId;
    public readonly ?string $customerName;
    public readonly ?string $allergyNote;
    /** @var list<OrderItem>|null */
    public readonly ?array $items;
    public readonly ?float $subtotal;
    public readonly ?OrderDelivery $delivery;
    public readonly ?\DateTimeImmutable $createdAt;
    public readonly ?\DateTimeImmutable $updatedAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->number = self::string($data, 'number');
        $model->dailyNumber = self::int($data, 'dailyNumber');
        $model->kind = self::string($data, 'kind');
        $model->orderType = self::string($data, 'orderType');
        $model->status = self::string($data, 'status');
        $model->tableId = self::string($data, 'tableId');
        $model->billId = self::string($data, 'billId');
        $model->customerName = self::string($data, 'customerName');
        $model->allergyNote = self::string($data, 'allergyNote');
        $model->items = self::listOf($data, 'items', [OrderItem::class, 'fromArray']);
        $model->subtotal = self::float($data, 'subtotal');
        $model->delivery = self::object($data, 'delivery', [OrderDelivery::class, 'fromArray']);
        $model->createdAt = self::dateTime($data, 'createdAt');
        $model->updatedAt = self::dateTime($data, 'updatedAt');

        return $model;
    }
}
