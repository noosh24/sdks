<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

final class Where
{
    /** @var list<string> */
    private array $conditions = [];

    public static function create(): self
    {
        return new self();
    }

    public function eq(string $field, string|int|float|bool|\DateTimeInterface $value): self
    {
        return $this->add($field, '=', $value);
    }

    public function ne(string $field, string|int|float|bool|\DateTimeInterface $value): self
    {
        return $this->add($field, '!=', $value);
    }

    public function gt(string $field, string|int|float|\DateTimeInterface $value): self
    {
        return $this->add($field, '>', $value);
    }

    public function gte(string $field, string|int|float|\DateTimeInterface $value): self
    {
        return $this->add($field, '>=', $value);
    }

    public function lt(string $field, string|int|float|\DateTimeInterface $value): self
    {
        return $this->add($field, '<', $value);
    }

    public function lte(string $field, string|int|float|\DateTimeInterface $value): self
    {
        return $this->add($field, '<=', $value);
    }

    /**
     * @param array<int, string|int|float|\DateTimeInterface> $values
     */
    public function in(string $field, array $values): self
    {
        if ($values === []) {
            throw new \InvalidArgumentException('in() needs at least one value');
        }
        $this->conditions[] = $this->field($field) . ' in (' . implode(', ', array_map([self::class, 'literal'], array_values($values))) . ')';

        return $this;
    }

    public function toString(): string
    {
        return implode(' AND ', $this->conditions);
    }

    public function __toString(): string
    {
        return $this->toString();
    }

    public static function literal(mixed $value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return "'" . $value->format(\DateTimeInterface::RFC3339) . "'";
        }
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        if (is_int($value) || is_float($value)) {
            if (is_float($value) && !is_finite($value)) {
                throw new \InvalidArgumentException('Numbers in where must be finite');
            }

            return is_int($value) ? (string) $value : rtrim(rtrim(sprintf('%.10F', $value), '0'), '.');
        }
        if (is_string($value)) {
            return "'" . str_replace("'", "''", $value) . "'";
        }
        throw new \InvalidArgumentException('where takes strings, numbers, booleans and dates');
    }

    private function add(string $field, string $operator, mixed $value): self
    {
        $this->conditions[] = $this->field($field) . ' ' . $operator . ' ' . self::literal($value);

        return $this;
    }

    private function field(string $field): string
    {
        if (!preg_match('/^[A-Za-z][A-Za-z0-9_.]*$/', $field)) {
            throw new \InvalidArgumentException(sprintf('"%s" is not a field name', $field));
        }

        return $field;
    }
}
