<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Review extends Model
{
    public readonly ?string $id;
    public readonly ?string $author;
    public readonly ?float $overall;
    public readonly ?ReviewRatings $ratings;
    public readonly ?string $body;
    public readonly ?string $visitType;
    public readonly ?\DateTimeImmutable $visitedOn;
    public readonly ?bool $verified;
    public readonly ?string $reply;
    public readonly ?\DateTimeImmutable $repliedAt;
    public readonly ?\DateTimeImmutable $createdAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->author = self::string($data, 'author');
        $model->overall = self::float($data, 'overall');
        $model->ratings = self::object($data, 'ratings', [ReviewRatings::class, 'fromArray']);
        $model->body = self::string($data, 'body');
        $model->visitType = self::string($data, 'visitType');
        $model->visitedOn = self::dateTime($data, 'visitedOn');
        $model->verified = self::bool($data, 'verified');
        $model->reply = self::string($data, 'reply');
        $model->repliedAt = self::dateTime($data, 'repliedAt');
        $model->createdAt = self::dateTime($data, 'createdAt');

        return $model;
    }
}
