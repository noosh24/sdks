<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class ModifierGroup extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?bool $required = null;
    public ?int $position = null;
    /** @var list<Modifier>|null */
    public ?array $modifiers = null;

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
