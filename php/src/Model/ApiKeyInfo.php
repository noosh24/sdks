<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ApiKeyInfo extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $prefix = null;
    /** @var list<string>|null */
    public ?array $scopes = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->prefix = self::string($data, 'prefix');
        $model->scopes = self::strings($data, 'scopes');

        return $model;
    }
}
