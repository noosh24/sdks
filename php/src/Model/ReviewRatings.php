<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReviewRatings extends Model
{
    public readonly ?float $food;
    public readonly ?float $service;
    public readonly ?float $atmosphere;
    public readonly ?float $cleanliness;
    public readonly ?float $price;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->food = self::float($data, 'food');
        $model->service = self::float($data, 'service');
        $model->atmosphere = self::float($data, 'atmosphere');
        $model->cleanliness = self::float($data, 'cleanliness');
        $model->price = self::float($data, 'price');

        return $model;
    }
}
