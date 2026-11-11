<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class LoyaltyCard extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $phone;
    public readonly ?int $stamps;
    public readonly ?int $totalStamps;
    public readonly ?int $redeemed;
    public readonly ?string $source;
    public readonly ?\DateTimeImmutable $lastVisitAt;
    public readonly ?\DateTimeImmutable $createdAt;
    public readonly ?\DateTimeImmutable $updatedAt;

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
