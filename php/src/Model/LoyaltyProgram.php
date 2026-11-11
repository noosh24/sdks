<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class LoyaltyProgram extends Model
{
    public readonly ?int $stampsNeeded;
    public readonly ?string $earnBy;
    public readonly ?float $minBill;
    public readonly ?bool $oncePerDay;
    public readonly ?string $rewardName;
    public readonly ?string $rewardScope;
    /** @var list<string>|null */
    public readonly ?array $rewardCategories;
    /** @var list<string>|null */
    public readonly ?array $rewardProductIds;
    public readonly ?float $rewardMaxPrice;
    public readonly ?string $terms;

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
