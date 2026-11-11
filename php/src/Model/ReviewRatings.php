<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ReviewRatings extends Model
{
    public ?float $food = null;
    public ?float $service = null;
    public ?float $atmosphere = null;
    public ?float $cleanliness = null;
    public ?float $price = null;

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
