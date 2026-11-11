<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class OrderDelivery extends Model
{
    public ?string $status = null;
    public ?DeliveryPlatform $platform = null;
    public ?string $address = null;
    public ?string $customerPhone = null;
    public ?string $courierName = null;
    public ?string $note = null;
    public ?string $paymentMethod = null;
    public ?float $fee = null;
    public ?float $platformTotal = null;
    public ?\DateTimeImmutable $acceptedAt = null;

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
