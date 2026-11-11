<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Subscription extends Model
{
    public ?string $status = null;
    /** @var list<string>|null */
    public ?array $modules = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->status = self::string($data, 'status');
        $model->modules = self::strings($data, 'modules');

        return $model;
    }
}
