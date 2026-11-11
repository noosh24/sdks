<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class TableAvailability extends Model
{
    public readonly ?\DateTimeImmutable $startsAt;
    public readonly ?\DateTimeImmutable $endsAt;
    public readonly ?int $durationMinutes;
    public readonly ?string $openTime;
    public readonly ?string $closeTime;
    /** @var list<AvailableTable>|null */
    public readonly ?array $tables;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->startsAt = self::dateTime($data, 'startsAt');
        $model->endsAt = self::dateTime($data, 'endsAt');
        $model->durationMinutes = self::int($data, 'durationMinutes');
        $model->openTime = self::string($data, 'openTime');
        $model->closeTime = self::string($data, 'closeTime');
        $model->tables = self::listOf($data, 'tables', [AvailableTable::class, 'fromArray']);

        return $model;
    }
}
