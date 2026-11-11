<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Exception;

class ApiException extends \RuntimeException implements Noosh24Exception
{
    private const BY_CODE = [
        'validation_error' => ValidationException::class,
        'no_api_key' => NoApiKeyException::class,
        'invalid_api_key' => InvalidApiKeyException::class,
        'insufficient_scope' => InsufficientScopeException::class,
        'module_not_enabled' => ModuleNotEnabledException::class,
        'venue_suspended' => VenueSuspendedException::class,
        'not_your_reservation' => NotYourReservationException::class,
        'not_found' => NotFoundException::class,
        'table_not_found' => TableNotFoundException::class,
        'table_taken' => TableTakenException::class,
        'cannot_cancel' => CannotCancelException::class,
        'outside_hours' => OutsideHoursException::class,
        'in_the_past' => InThePastException::class,
        'table_too_small' => TableTooSmallException::class,
        'rate_limit_exceeded' => RateLimitException::class,
        'temporarily_unavailable' => TemporarilyUnavailableException::class,
    ];

    private const BY_STATUS = [
        400 => ValidationException::class,
        401 => AuthenticationException::class,
        403 => PermissionDeniedException::class,
        404 => NotFoundException::class,
        409 => ConflictException::class,
        422 => UnprocessableException::class,
        429 => RateLimitException::class,
    ];

    /** @var array<string, string> */
    private readonly array $headers;

    /**
     * @param array<string, string> $headers
     */
    final public function __construct(
        private readonly int $status,
        private readonly ?string $errorCode,
        string $message,
        array $headers = [],
        private readonly string $body = '',
    ) {
        parent::__construct($message, $status);
        $this->headers = array_change_key_case($headers, CASE_LOWER);
    }

    /**
     * @param array<string, string> $headers
     */
    public static function fromResponse(int $status, array $headers, string $body): self
    {
        $code = null;
        $message = '';
        $decoded = json_decode($body, true);
        if (is_array($decoded)) {
            $code = isset($decoded['error']) && is_string($decoded['error']) ? $decoded['error'] : null;
            $message = isset($decoded['message']) && is_string($decoded['message']) ? $decoded['message'] : '';
        }
        if ($message === '') {
            $message = $code ?? sprintf('HTTP %d', $status);
        }
        $class = self::BY_CODE[$code ?? ''] ?? self::BY_STATUS[$status] ?? ($status >= 500 ? ServerException::class : self::class);

        return new $class($status, $code, $message, $headers, $body);
    }

    public function getStatus(): int
    {
        return $this->status;
    }

    public function getErrorCode(): ?string
    {
        return $this->errorCode;
    }

    /**
     * @return array<string, string>
     */
    public function getHeaders(): array
    {
        return $this->headers;
    }

    public function getHeader(string $name): ?string
    {
        return $this->headers[strtolower($name)] ?? null;
    }

    public function getBody(): string
    {
        return $this->body;
    }
}
