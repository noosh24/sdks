<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Product extends Model
{
    public ?string $id = null;
    public ?string $name = null;
    public ?string $category = null;
    public ?string $description = null;
    public ?float $price = null;
    public ?bool $available = null;
    public ?bool $popular = null;
    public ?int $position = null;
    public ?int $prepMinutes = null;
    public ?string $station = null;
    public ?float $vatRate = null;
    public ?bool $vegetarian = null;
    public ?bool $spicy = null;
    /** @var list<string>|null */
    public ?array $allergens = null;
    public ?bool $discountable = null;
    public ?bool $hasModifiers = null;
    public ?string $image = null;
    public ?string $video = null;
    /** @var list<ModifierGroup>|null */
    public ?array $modifierGroups = null;
    /** @var array<string, ProductTranslation>|null */
    public ?array $translations = null;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->category = self::string($data, 'category');
        $model->description = self::string($data, 'description');
        $model->price = self::float($data, 'price');
        $model->available = self::bool($data, 'available');
        $model->popular = self::bool($data, 'popular');
        $model->position = self::int($data, 'position');
        $model->prepMinutes = self::int($data, 'prepMinutes');
        $model->station = self::string($data, 'station');
        $model->vatRate = self::float($data, 'vatRate');
        $model->vegetarian = self::bool($data, 'vegetarian');
        $model->spicy = self::bool($data, 'spicy');
        $model->allergens = self::strings($data, 'allergens');
        $model->discountable = self::bool($data, 'discountable');
        $model->hasModifiers = self::bool($data, 'hasModifiers');
        $model->image = self::string($data, 'image');
        $model->video = self::string($data, 'video');
        $model->modifierGroups = self::listOf($data, 'modifierGroups', [ModifierGroup::class, 'fromArray']);
        $model->translations = self::mapOf($data, 'translations', [ProductTranslation::class, 'fromArray']);

        return $model;
    }
}
