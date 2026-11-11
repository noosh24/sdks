<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Http;

use Noosh24\OpenApi\Exception\ConnectionException;

interface Transport
{
    /**
     * @throws ConnectionException
     */
    public function send(Request $request, float $timeout): Response;
}
