<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class OrderItem extends Model
{
    public ?string $id = null;
    public ?string $productId = null;
    public ?string $name = null;
    public ?int $qty = null;
    public ?float $price = null;
    public ?float $listPrice = null;
    public ?string $modifiers = null;
    public ?string $note = null;
    public ?string $status = null;
    public ?bool $comp = null;
    public ?string $campaign = null;
    public ?string $cancelReason = null;

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
