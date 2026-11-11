<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\LoyaltyCard;
use Noosh24\OpenApi\Model\LoyaltyProgram;
use Noosh24\OpenApi\Page;

final class Loyalty extends Resource
{
    public function getProgram(): LoyaltyProgram
    {
        return $this->fetchOne('/loyalty/program', [], [LoyaltyProgram::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return Page<LoyaltyCard>
     */
    public function listCards(array $params = []): Page
    {
        return $this->fetchPage('/loyalty/cards', $params, [LoyaltyCard::class, 'fromArray']);
    }

    /**
     * @param array{limit?: int, offset?: int, sort?: string|list<string>, where?: string|\Noosh24\OpenApi\Where} $params
     * @return \Generator<int, LoyaltyCard>
     */
    public function iterateCards(array $params = []): \Generator
    {
        return $this->paginate('/loyalty/cards', $params, [LoyaltyCard::class, 'fromArray'], 100);
    }
}
