<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Client;
use Noosh24\OpenApi\Exception\ApiException;
use Noosh24\OpenApi\Exception\ConnectionException;
use Noosh24\OpenApi\Exception\RateLimitException;
use Noosh24\OpenApi\Exception\TemporarilyUnavailableException;
use Noosh24\OpenApi\Http\Response;

final class ClientTest extends TestCase
{
    public function testSendsKeyAndHeadersToTheDefaultBaseUrl(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => [
            'restaurant' => ['id' => 'r1', 'name' => 'Masago', 'slug' => 'masago'],
            'key' => ['id' => 'k1', 'name' => 'Wolt', 'prefix' => 'nsk_Ab3dE9xQ', 'scopes' => ['menu:read', 'orders:read']],
            'subscription' => ['status' => 'active', 'modules' => ['loyalty']],
            'features' => ['loyalty' => true, 'inventory' => false],
        ]]);

        $me = $client->whoami();

        $request = $this->http->last();
        self::assertSame('GET', $request->method);
        self::assertSame('https://open-api.noosh24.com/v1/whoami', $request->url);
        self::assertSame('Bearer nsk_test_123', $request->headers['Authorization']);
        self::assertSame('application/json', $request->headers['Accept']);
        self::assertStringStartsWith('noosh24-php/' . Client::VERSION, $request->headers['User-Agent']);
        self::assertNull($request->body);
        self::assertSame(30.0, $this->http->timeouts[0]);

        self::assertSame('Masago', $me->restaurant->name);
        self::assertSame(['menu:read', 'orders:read'], $me->key->scopes);
        self::assertSame('active', $me->subscription->status);
        self::assertTrue($me->features->loyalty);
        self::assertFalse($me->features->inventory);
    }

    public function testCustomBaseUrlTimeoutAndUserAgent(): void
    {
        $client = $this->client(['baseUrl' => 'http://localhost:8080/v1/', 'timeout' => 5, 'userAgent' => 'acme-pos/2.1']);
        $this->http->json(200, ['data' => []]);

        $client->whoami();

        self::assertSame('http://localhost:8080/v1/whoami', $this->http->last()->url);
        self::assertSame(5.0, $this->http->timeouts[0]);
        self::assertStringStartsWith('acme-pos/2.1 noosh24-php/', $this->http->last()->headers['User-Agent']);
    }

    public function testRejectsAnEmptyKey(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        new Client('  ');
    }

    public function testRetriesRateLimitAfterRetryAfter(): void
    {
        $client = $this->client();
        $this->http
            ->json(429, ['error' => 'rate_limit_exceeded', 'message' => 'slow down'], ['Retry-After' => '3'])
            ->json(200, ['data' => ['items' => [], 'total' => 0]]);

        self::assertSame([], $client->tables->list());
        self::assertCount(2, $this->http->requests);
        self::assertSame([3.0], $this->sleeps);
    }

    public function testGivesUpAfterMaxRetries(): void
    {
        $client = $this->client(['maxRetries' => 1]);
        $this->http
            ->json(429, ['error' => 'rate_limit_exceeded', 'message' => 'slow down'], ['Retry-After' => '1'])
            ->json(429, ['error' => 'rate_limit_exceeded', 'message' => 'slow down'], ['Retry-After' => '7']);

        try {
            $client->tables->list();
            self::fail('expected RateLimitException');
        } catch (RateLimitException $e) {
            self::assertSame(429, $e->getStatus());
            self::assertSame('rate_limit_exceeded', $e->getErrorCode());
            self::assertSame(7, $e->getRetryAfter());
            self::assertSame('slow down', $e->getMessage());
        }
        self::assertCount(2, $this->http->requests);
    }

    public function testDoesNotWaitLongerThanAMinute(): void
    {
        $client = $this->client();
        $this->http->json(429, ['error' => 'rate_limit_exceeded'], ['Retry-After' => '120']);

        $this->expectException(RateLimitException::class);
        try {
            $client->tables->list();
        } finally {
            self::assertCount(1, $this->http->requests);
            self::assertSame([], $this->sleeps);
        }
    }

    public function testBacksOffOnTemporarilyUnavailable(): void
    {
        $client = $this->client();
        $this->http
            ->json(503, ['error' => 'temporarily_unavailable', 'message' => 'try again'])
            ->json(503, ['error' => 'temporarily_unavailable', 'message' => 'try again'])
            ->json(503, ['error' => 'temporarily_unavailable', 'message' => 'try again']);

        $this->expectException(TemporarilyUnavailableException::class);
        try {
            $client->tables->listHalls();
        } finally {
            self::assertCount(3, $this->http->requests);
            self::assertSame([0.5, 1.0], $this->sleeps);
        }
    }

    public function testRetriesConnectionErrorsOnReads(): void
    {
        $client = $this->client();
        $this->http
            ->fail(new ConnectionException('Connection reset'))
            ->json(200, ['data' => ['items' => [['id' => 'h1', 'name' => 'Main', 'position' => 1]], 'total' => 1]]);

        $halls = $client->tables->listHalls();

        self::assertSame('Main', $halls[0]->name);
        self::assertCount(2, $this->http->requests);
    }

    public function testNonJsonBodyIsAnApiError(): void
    {
        $client = $this->client();
        $this->http->raw(new Response(200, [], '<html>gateway</html>'));

        $this->expectException(ApiException::class);
        $client->whoami();
    }

    public function testBuildsRepeatedQueryParameters(): void
    {
        self::assertSame(
            'sort=price%20desc&sort=name%20asc&where=category%20%3D%20%27Salads%27&available=true',
            Client::buildQuery(['sort' => ['price desc', 'name asc'], 'where' => "category = 'Salads'", 'skip' => null, 'available' => true])
        );
    }
}
