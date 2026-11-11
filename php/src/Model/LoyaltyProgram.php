<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class LoyaltyProgram extends Model
{
    public ?int $stampsNeeded = null;
    public ?string $earnBy = null;
    public ?float $minBill = null;
    public ?bool $oncePerDay = null;
    public ?string $rewardName = null;
    public ?string $rewardScope = null;
    /** @var list<string>|null */
    public ?array $rewardCategories = null;
    /** @var list<string>|null */
    public ?array $rewardProductIds = null;
    public ?float $rewardMaxPrice = null;
    public ?string $terms = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->stampsNeeded = self::int($data, 'stampsNeeded');
        $model->earnBy = self::string($data, 'earnBy');
        $model->minBill = self::float($data, 'minBill');
        $model->oncePerDay = self::bool($data, 'oncePerDay');
        $model->rewardName = self::string($data, 'rewardName');
        $model->rewardScope = self::string($data, 'rewardScope');
        $model->rewardCategories = self::strings($data, 'rewardCategories');
        $model->rewardProductIds = self::strings($data, 'rewardProductIds');
        $model->rewardMaxPrice = self::float($data, 'rewardMaxPrice');
        $model->terms = self::string($data, 'terms');

        return $model;
    }
}
