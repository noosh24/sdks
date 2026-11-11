<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReservationPreOrderItem extends Model
{
    public ?string $productId = null;
    public ?string $name = null;
    public ?float $price = null;
    public ?int $qty = null;
    public ?string $note = null;

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
