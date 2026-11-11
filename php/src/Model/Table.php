<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Table extends Model
{
    public readonly ?string $id;
    public readonly ?string $label;
    public readonly ?string $hallId;
    public readonly ?string $zone;
    public readonly ?int $seats;
    public readonly ?string $shape;
    public readonly ?string $status;
    public readonly ?int $guests;
    public readonly ?string $waiter;
    public readonly ?string $seatedSince;
    public readonly ?int $openOrders;
    public readonly ?string $billId;
    public readonly ?float $billTotal;
    public readonly ?bool $billRequested;
    public readonly ?bool $billSettled;
    public readonly ?string $mergedInto;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->label = self::string($data, 'label');
        $model->hallId = self::string($data, 'hallId');
        $model->zone = self::string($data, 'zone');
        $model->seats = self::int($data, 'seats');
        $model->shape = self::string($data, 'shape');
        $model->status = self::string($data, 'status');
        $model->guests = self::int($data, 'guests');
        $model->waiter = self::string($data, 'waiter');
        $model->seatedSince = self::string($data, 'seatedSince');
        $model->openOrders = self::int($data, 'openOrders');
        $model->billId = self::string($data, 'billId');
        $model->billTotal = self::float($data, 'billTotal');
        $model->billRequested = self::bool($data, 'billRequested');
        $model->billSettled = self::bool($data, 'billSettled');
        $model->mergedInto = self::string($data, 'mergedInto');

        return $model;
    }
}
