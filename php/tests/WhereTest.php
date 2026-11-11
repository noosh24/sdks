<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Where;

final class WhereTest extends \PHPUnit\Framework\TestCase
{
    public function testBuildsAndOnlyConditions(): void
    {
        $where = Where::create()
            ->eq('category', 'Salads')
            ->ne('station', '')
            ->gt('price', 4.75)
            ->lte('prepMinutes', 15)
            ->eq('vegetarian', false)
            ->gte('createdAt', new \DateTimeImmutable('2026-11-01T18:00:00+04:00'))
            ->lt('price', 20.0)
            ->in('id', ['7f0c', "O'Neil", 3]);

        self::assertSame(
            "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false"
            . " AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)",
            (string) $where
        );
    }

    public function testEmptyBuilderIsAnEmptyString(): void
    {
        self::assertSame('', Where::create()->toString());
    }

    public function testRejectsBadFieldNames(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        Where::create()->eq("price = 1 OR 1", 1);
    }

    public function testRejectsEmptyIn(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        Where::create()->in('id', []);
    }

    public function testRejectsNull(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        Where::literal(null);
    }
}
