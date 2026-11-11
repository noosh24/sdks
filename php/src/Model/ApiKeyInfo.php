<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ApiKeyInfo extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $prefix;
    /** @var list<string>|null */
    public readonly ?array $scopes;

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
