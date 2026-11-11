<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ModifierGroup extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?bool $required;
    public readonly ?int $position;
    /** @var list<Modifier>|null */
    public readonly ?array $modifiers;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->required = self::bool($data, 'required');
        $model->position = self::int($data, 'position');
        $model->modifiers = self::listOf($data, 'modifiers', [Modifier::class, 'fromArray']);

        return $model;
    }
}
