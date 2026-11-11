<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Subscription extends Model
{
    public readonly ?string $status;
    /** @var list<string>|null */
    public readonly ?array $modules;

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
