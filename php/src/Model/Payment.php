<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Payment extends Model
{
    public ?string $id = null;
    public ?string $status = null;
    public ?string $method = null;
    public ?string $recordedMethod = null;
    public ?float $amount = null;
    public ?float $tip = null;
    public ?float $refundedAmount = null;
    public ?\DateTimeImmutable $refundedAt = null;
    public ?string $refundReason = null;
    public ?string $billId = null;
    public ?string $reservationId = null;
    public ?string $orderId = null;
    public ?string $takenAt = null;
    public ?PaymentCard $card = null;
    public ?PaymentPlatform $platform = null;
    public ?\DateTimeImmutable $createdAt = null;
    public ?\DateTimeImmutable $settledAt = null;

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
