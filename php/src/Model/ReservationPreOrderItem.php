<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReservationPreOrderItem extends Model
{
    public readonly ?string $productId;
    public readonly ?string $name;
    public readonly ?float $price;
    public readonly ?int $qty;
    public readonly ?string $note;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->productId = self::string($data, 'productId');
        $model->name = self::string($data, 'name');
        $model->price = self::float($data, 'price');
        $model->qty = self::int($data, 'qty');
        $model->note = self::string($data, 'note');

        return $model;
    }
}
