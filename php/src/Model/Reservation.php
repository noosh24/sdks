<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Reservation extends Model
{
    public ?string $id = null;
    public ?string $code = null;
    public ?string $status = null;
    public ?string $source = null;
    public ?\DateTimeImmutable $startsAt = null;
    public ?\DateTimeImmutable $endsAt = null;
    public ?int $guests = null;
    public ?string $zone = null;
    public ?ReservationTable $table = null;
    public ?ReservationGuest $guest = null;
    public ?string $specialRequest = null;
    public ?string $allergyNote = null;
    public ?bool $birthday = null;
    public ?bool $childChair = null;
    public ?float $depositPaid = null;
    /** @var list<ReservationPreOrderItem>|null */
    public ?array $preOrder = null;
    public ?string $externalRef = null;
    public ?\DateTimeImmutable $decidedAt = null;
    public ?\DateTimeImmutable $createdAt = null;
    public ?\DateTimeImmutable $updatedAt = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->code = self::string($data, 'code');
        $model->status = self::string($data, 'status');
        $model->source = self::string($data, 'source');
        $model->startsAt = self::dateTime($data, 'startsAt');
        $model->endsAt = self::dateTime($data, 'endsAt');
        $model->guests = self::int($data, 'guests');
        $model->zone = self::string($data, 'zone');
        $model->table = self::object($data, 'table', [ReservationTable::class, 'fromArray']);
        $model->guest = self::object($data, 'guest', [ReservationGuest::class, 'fromArray']);
        $model->specialRequest = self::string($data, 'specialRequest');
        $model->allergyNote = self::string($data, 'allergyNote');
        $model->birthday = self::bool($data, 'birthday');
        $model->childChair = self::bool($data, 'childChair');
        $model->depositPaid = self::float($data, 'depositPaid');
        $model->preOrder = self::listOf($data, 'preOrder', [ReservationPreOrderItem::class, 'fromArray']);
        $model->externalRef = self::string($data, 'externalRef');
        $model->decidedAt = self::dateTime($data, 'decidedAt');
        $model->createdAt = self::dateTime($data, 'createdAt');
        $model->updatedAt = self::dateTime($data, 'updatedAt');

        return $model;
    }
}
