<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class OrderItem extends Model
{
    public readonly ?string $id;
    public readonly ?string $productId;
    public readonly ?string $name;
    public readonly ?int $qty;
    public readonly ?float $price;
    public readonly ?float $listPrice;
    public readonly ?string $modifiers;
    public readonly ?string $note;
    public readonly ?string $status;
    public readonly ?bool $comp;
    public readonly ?string $campaign;
    public readonly ?string $cancelReason;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->productId = self::string($data, 'productId');
        $model->name = self::string($data, 'name');
        $model->qty = self::int($data, 'qty');
        $model->price = self::float($data, 'price');
        $model->listPrice = self::float($data, 'listPrice');
        $model->modifiers = self::string($data, 'modifiers');
        $model->note = self::string($data, 'note');
        $model->status = self::string($data, 'status');
        $model->comp = self::bool($data, 'comp');
        $model->campaign = self::string($data, 'campaign');
        $model->cancelReason = self::string($data, 'cancelReason');

        return $model;
    }
}
