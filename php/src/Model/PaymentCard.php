<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class PaymentCard extends Model
{
    public readonly ?string $maskedPan;
    public readonly ?string $scheme;
    public readonly ?string $bank;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->maskedPan = self::string($data, 'maskedPan');
        $model->scheme = self::string($data, 'scheme');
        $model->bank = self::string($data, 'bank');

        return $model;
    }
}
