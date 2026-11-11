<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Reservation extends Model
{
    public readonly ?string $id;
    public readonly ?string $code;
    public readonly ?string $status;
    public readonly ?string $source;
    public readonly ?\DateTimeImmutable $startsAt;
    public readonly ?\DateTimeImmutable $endsAt;
    public readonly ?int $guests;
    public readonly ?string $zone;
    public readonly ?ReservationTable $table;
    public readonly ?ReservationGuest $guest;
    public readonly ?string $specialRequest;
    public readonly ?string $allergyNote;
    public readonly ?bool $birthday;
    public readonly ?bool $childChair;
    public readonly ?float $depositPaid;
    /** @var list<ReservationPreOrderItem>|null */
    public readonly ?array $preOrder;
    public readonly ?string $externalRef;
    public readonly ?\DateTimeImmutable $decidedAt;
    public readonly ?\DateTimeImmutable $createdAt;
    public readonly ?\DateTimeImmutable $updatedAt;

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
