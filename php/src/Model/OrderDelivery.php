<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class OrderDelivery extends Model
{
    public readonly ?string $status;
    public readonly ?DeliveryPlatform $platform;
    public readonly ?string $address;
    public readonly ?string $customerPhone;
    public readonly ?string $courierName;
    public readonly ?string $note;
    public readonly ?string $paymentMethod;
    public readonly ?float $fee;
    public readonly ?float $platformTotal;
    public readonly ?\DateTimeImmutable $acceptedAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->status = self::string($data, 'status');
        $model->platform = self::object($data, 'platform', [DeliveryPlatform::class, 'fromArray']);
        $model->address = self::string($data, 'address');
        $model->customerPhone = self::string($data, 'customerPhone');
        $model->courierName = self::string($data, 'courierName');
        $model->note = self::string($data, 'note');
        $model->paymentMethod = self::string($data, 'paymentMethod');
        $model->fee = self::float($data, 'fee');
        $model->platformTotal = self::float($data, 'platformTotal');
        $model->acceptedAt = self::dateTime($data, 'acceptedAt');

        return $model;
    }
}
