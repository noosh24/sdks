<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Order extends Model
{
    public ?string $id = null;
    public ?string $number = null;
    public ?int $dailyNumber = null;
    public ?string $kind = null;
    public ?string $orderType = null;
    public ?string $status = null;
    public ?string $tableId = null;
    public ?string $billId = null;
    public ?string $customerName = null;
    public ?string $allergyNote = null;
    /** @var list<OrderItem>|null */
    public ?array $items = null;
    public ?float $subtotal = null;
    public ?OrderDelivery $delivery = null;
    public ?\DateTimeImmutable $createdAt = null;
    public ?\DateTimeImmutable $updatedAt = null;

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
