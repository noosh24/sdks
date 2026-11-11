<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Exception;
use PHPUnit\Framework\Attributes\DataProvider;

final class ErrorsTest extends TestCase
{
    /**
     * @return iterable<string, array{int, ?string, class-string, class-string}>
     */
    public static function cases(): iterable
    {
        yield 'validation_error' => [400, 'validation_error', Exception\ValidationException::class, Exception\ApiException::class];
        yield 'no_api_key' => [401, 'no_api_key', Exception\NoApiKeyException::class, Exception\AuthenticationException::class];
        yield 'invalid_api_key' => [401, 'invalid_api_key', Exception\InvalidApiKeyException::class, Exception\AuthenticationException::class];
        yield 'insufficient_scope' => [403, 'insufficient_scope', Exception\InsufficientScopeException::class, Exception\PermissionDeniedException::class];
        yield 'module_not_enabled' => [403, 'module_not_enabled', Exception\ModuleNotEnabledException::class, Exception\PermissionDeniedException::class];
        yield 'venue_suspended' => [403, 'venue_suspended', Exception\VenueSuspendedException::class, Exception\PermissionDeniedException::class];
        yield 'not_your_reservation' => [403, 'not_your_reservation', Exception\NotYourReservationException::class, Exception\PermissionDeniedException::class];
        yield 'not_found' => [404, 'not_found', Exception\NotFoundException::class, Exception\ApiException::class];
        yield 'table_not_found' => [404, 'table_not_found', Exception\TableNotFoundException::class, Exception\NotFoundException::class];
        yield 'table_taken' => [409, 'table_taken', Exception\TableTakenException::class, Exception\ConflictException::class];
        yield 'cannot_cancel' => [409, 'cannot_cancel', Exception\CannotCancelException::class, Exception\ConflictException::class];
        yield 'outside_hours' => [422, 'outside_hours', Exception\OutsideHoursException::class, Exception\UnprocessableException::class];
        yield 'in_the_past' => [422, 'in_the_past', Exception\InThePastException::class, Exception\UnprocessableException::class];
        yield 'table_too_small' => [422, 'table_too_small', Exception\TableTooSmallException::class, Exception\UnprocessableException::class];
        yield 'rate_limit_exceeded' => [429, 'rate_limit_exceeded', Exception\RateLimitException::class, Exception\ApiException::class];
        yield 'temporarily_unavailable' => [503, 'temporarily_unavailable', Exception\TemporarilyUnavailableException::class, Exception\ServerException::class];
        yield 'unknown 403' => [403, 'something_new', Exception\PermissionDeniedException::class, Exception\ApiException::class];
        yield 'unknown 409' => [409, 'something_new', Exception\ConflictException::class, Exception\ApiException::class];
        yield 'query_failed' => [500, 'query_failed', Exception\ServerException::class, Exception\ApiException::class];
        yield 'no body code' => [418, null, Exception\ApiException::class, Exception\Noosh24Exception::class];
    }

    /**
     * @param class-string $class
     * @param class-string $parent
     */
    #[DataProvider('cases')]
    public function testMapsErrorCodes(int $status, ?string $code, string $class, string $parent): void
    {
        $client = $this->client(['maxRetries' => 0]);
        $this->http->json($status, $code === null ? ['nope' => true] : ['error' => $code, 'message' => 'Mesaj']);

        try {
            $client->customers->get('c1');
            self::fail('expected ' . $class);
        } catch (Exception\ApiException $e) {
            self::assertSame($class, get_class($e));
            self::assertInstanceOf($parent, $e);
            self::assertInstanceOf(Exception\Noosh24Exception::class, $e);
            self::assertSame($status, $e->getStatus());
            self::assertSame($code, $e->getErrorCode());
            self::assertSame($code === null ? 'HTTP ' . $status : 'Mesaj', $e->getMessage());
        }
    }

    public function testValidationErrorIsNotRetried(): void
    {
        $client = $this->client();
        $this->http->json(400, ['error' => 'validation_error', 'message' => '"nope" is not a filterable field on this resource']);

        $this->expectException(Exception\ValidationException::class);
        $this->expectExceptionMessage('"nope" is not a filterable field on this resource');
        try {
            $client->menu->listProducts(['where' => 'nope = 1']);
        } finally {
            self::assertCount(1, $this->http->requests);
        }
    }
}
