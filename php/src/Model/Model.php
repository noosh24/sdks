<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Model;

abstract class Model implements \JsonSerializable
{
    /**
     * @param array<string, mixed> $raw
     */
    final protected function __construct(private readonly array $raw)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return $this->raw;
    }

    /**
     * @return array<string, mixed>
     */
    public function jsonSerialize(): array
    {
        return $this->raw;
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function string(array $data, string $key): ?string
    {
        if (!isset($data[$key]) || is_array($data[$key])) {
            return null;
        }

        return (string) $data[$key];
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function int(array $data, string $key): ?int
    {
        return isset($data[$key]) && is_numeric($data[$key]) ? (int) $data[$key] : null;
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function float(array $data, string $key): ?float
    {
        return isset($data[$key]) && is_numeric($data[$key]) ? (float) $data[$key] : null;
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function bool(array $data, string $key): ?bool
    {
        return isset($data[$key]) && is_scalar($data[$key]) ? (bool) $data[$key] : null;
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function dateTime(array $data, string $key): ?\DateTimeImmutable
    {
        if (!isset($data[$key]) || !is_string($data[$key]) || $data[$key] === '') {
            return null;
        }
        $value = preg_replace('/(\.\d{6})\d+/', '$1', $data[$key]);
        try {
            return new \DateTimeImmutable((string) $value);
        } catch (\Exception) {
            return null;
        }
    }

    /**
     * @param array<string, mixed> $data
     * @return list<string>|null
     */
    protected static function strings(array $data, string $key): ?array
    {
        if (!isset($data[$key]) || !is_array($data[$key])) {
            return null;
        }

        return array_values(array_map('strval', array_filter($data[$key], 'is_scalar')));
    }

    /**
     * @param array<string, mixed> $data
     * @return array<string, float>|null
     */
    protected static function floats(array $data, string $key): ?array
    {
        if (!isset($data[$key]) || !is_array($data[$key])) {
            return null;
        }
        $out = [];
        foreach ($data[$key] as $name => $value) {
            if (is_numeric($value)) {
                $out[(string) $name] = (float) $value;
            }
        }

        return $out;
    }

    /**
     * @template T
     * @param array<string, mixed> $data
     * @param callable(array<string, mixed>): T $factory
     * @return T|null
     */
    protected static function object(array $data, string $key, callable $factory): mixed
    {
        if (!isset($data[$key]) || !is_array($data[$key])) {
            return null;
        }

        return $factory($data[$key]);
    }

    /**
     * @template T
     * @param array<string, mixed> $data
     * @param callable(array<string, mixed>): T $factory
     * @return list<T>|null
     */
    protected static function listOf(array $data, string $key, callable $factory): ?array
    {
        if (!isset($data[$key]) || !is_array($data[$key])) {
            return null;
        }
        $out = [];
        foreach ($data[$key] as $item) {
            if (is_array($item)) {
                $out[] = $factory($item);
            }
        }

        return $out;
    }

    /**
     * @template T
     * @param array<string, mixed> $data
     * @param callable(array<string, mixed>): T $factory
     * @return array<string, T>|null
     */
    protected static function mapOf(array $data, string $key, callable $factory): ?array
    {
        if (!isset($data[$key]) || !is_array($data[$key])) {
            return null;
        }
        $out = [];
        foreach ($data[$key] as $name => $item) {
            if (is_array($item)) {
                $out[(string) $name] = $factory($item);
            }
        }

        return $out;
    }
}
