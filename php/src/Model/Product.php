<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Product extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $category;
    public readonly ?string $description;
    public readonly ?float $price;
    public readonly ?bool $available;
    public readonly ?bool $popular;
    public readonly ?int $position;
    public readonly ?int $prepMinutes;
    public readonly ?string $station;
    public readonly ?float $vatRate;
    public readonly ?bool $vegetarian;
    public readonly ?bool $spicy;
    /** @var list<string>|null */
    public readonly ?array $allergens;
    public readonly ?bool $discountable;
    public readonly ?bool $hasModifiers;
    public readonly ?string $image;
    public readonly ?string $video;
    /** @var list<ModifierGroup>|null */
    public readonly ?array $modifierGroups;
    /** @var array<string, ProductTranslation>|null */
    public readonly ?array $translations;

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
