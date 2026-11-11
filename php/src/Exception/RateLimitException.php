<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Exception;

class RateLimitException extends ApiException
{
    public function getRetryAfter(): ?int
    {
        $value = $this->getHeader('retry-after');
        if ($value === null || !is_numeric($value)) {
            return null;
        }

        return max(0, (int) $value);
    }
}
