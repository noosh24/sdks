<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

final class Customer extends Model
{
    public readonly ?string $id;
    public readonly ?string $name;
    public readonly ?string $phone;
    public readonly ?string $note;
    public readonly ?\DateTimeImmutable $createdAt;
    public readonly ?\DateTimeImmutable $updatedAt;

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        $model = new self($data);
        $model->id = self::string($data, 'id');
        $model->name = self::string($data, 'name');
        $model->phone = self::string($data, 'phone');
        $model->note = self::string($data, 'note');
        $model->createdAt = self::dateTime($data, 'createdAt');
        $model->updatedAt = self::dateTime($data, 'updatedAt');

        return $model;
    }
}
