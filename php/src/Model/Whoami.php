<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Whoami extends Model
{
    public readonly ?Restaurant $restaurant;
    public readonly ?ApiKeyInfo $key;
    public readonly ?Subscription $subscription;
    public readonly ?Features $features;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->restaurant = self::object($data, 'restaurant', [Restaurant::class, 'fromArray']);
        $model->key = self::object($data, 'key', [ApiKeyInfo::class, 'fromArray']);
        $model->subscription = self::object($data, 'subscription', [Subscription::class, 'fromArray']);
        $model->features = self::object($data, 'features', [Features::class, 'fromArray']);

        return $model;
    }
}
