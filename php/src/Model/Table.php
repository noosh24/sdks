<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Table extends Model
{
    public ?string $id = null;
    public ?string $label = null;
    public ?string $hallId = null;
    public ?string $zone = null;
    public ?int $seats = null;
    public ?string $shape = null;
    public ?string $status = null;
    public ?int $guests = null;
    public ?string $waiter = null;
    public ?string $seatedSince = null;
    public ?int $openOrders = null;
    public ?string $billId = null;
    public ?float $billTotal = null;
    public ?bool $billRequested = null;
    public ?bool $billSettled = null;
    public ?string $mergedInto = null;

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
