<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class LoyaltyCard extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $phone = null;
    public ?int $stamps = null;
    public ?int $totalStamps = null;
    public ?int $redeemed = null;
    public ?string $source = null;
    public ?\DateTimeImmutable $lastVisitAt = null;
    public ?\DateTimeImmutable $createdAt = null;
    public ?\DateTimeImmutable $updatedAt = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->phone = self::string($data, 'phone');
        $model->stamps = self::int($data, 'stamps');
        $model->totalStamps = self::int($data, 'totalStamps');
        $model->redeemed = self::int($data, 'redeemed');
        $model->source = self::string($data, 'source');
        $model->lastVisitAt = self::dateTime($data, 'lastVisitAt');
        $model->createdAt = self::dateTime($data, 'createdAt');
        $model->updatedAt = self::dateTime($data, 'updatedAt');

        return $model;
    }
}
