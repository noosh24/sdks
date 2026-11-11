<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class TableAvailability extends Model
{
    public ?\DateTimeImmutable $startsAt = null;
    public ?\DateTimeImmutable $endsAt = null;
    public ?int $durationMinutes = null;
    public ?string $openTime = null;
    public ?string $closeTime = null;
    /** @var list<AvailableTable>|null */
    public ?array $tables = null;

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
