<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Payment extends Model
{
    public readonly ?string $id;
    public readonly ?string $status;
    public readonly ?string $method;
    public readonly ?string $recordedMethod;
    public readonly ?float $amount;
    public readonly ?float $tip;
    public readonly ?float $refundedAmount;
    public readonly ?\DateTimeImmutable $refundedAt;
    public readonly ?string $refundReason;
    public readonly ?string $billId;
    public readonly ?string $reservationId;
    public readonly ?string $orderId;
    public readonly ?string $takenAt;
    public readonly ?PaymentCard $card;
    public readonly ?PaymentPlatform $platform;
    public readonly ?\DateTimeImmutable $createdAt;
    public readonly ?\DateTimeImmutable $settledAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->status = self::string($data, 'status');
        $model->method = self::string($data, 'method');
        $model->recordedMethod = self::string($data, 'recordedMethod');
        $model->amount = self::float($data, 'amount');
        $model->tip = self::float($data, 'tip');
        $model->refundedAmount = self::float($data, 'refundedAmount');
        $model->refundedAt = self::dateTime($data, 'refundedAt');
        $model->refundReason = self::string($data, 'refundReason');
        $model->billId = self::string($data, 'billId');
        $model->reservationId = self::string($data, 'reservationId');
        $model->orderId = self::string($data, 'orderId');
        $model->takenAt = self::string($data, 'takenAt');
        $model->card = self::object($data, 'card', [PaymentCard::class, 'fromArray']);
        $model->platform = self::object($data, 'platform', [PaymentPlatform::class, 'fromArray']);
        $model->createdAt = self::dateTime($data, 'createdAt');
        $model->settledAt = self::dateTime($data, 'settledAt');

        return $model;
    }
}
