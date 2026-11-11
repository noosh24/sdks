<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Http\Request;
use Noosh24\OpenApi\Http\Response;
use Noosh24\OpenApi\Http\Transport;

final class MockTransport implements Transport
{
    /** @var list<Response|\Throwable> */
    private array $queue = [];

    /** @var list<Request> */
    public array $requests = [];

    /** @var list<float> */
    public array $timeouts = [];

    /**
     * @param mixed $body
     * @param array<string, string> $headers
     */
    public function json(int $status, $body, array $headers = []): self
    {
        $this->queue[] = new Response($status, $headers + ['Content-Type' => 'application/json'], json_encode($body, JSON_THROW_ON_ERROR));

        return $this;
    }

    public function raw(Response $response): self
    {
        $this->queue[] = $response;

        return $this;
    }

    public function fail(\Throwable $error): self
    {
        $this->queue[] = $error;

        return $this;
    }

    public function send(Request $request, float $timeout): Response
    {
        $this->requests[] = $request;
        $this->timeouts[] = $timeout;
        $next = array_shift($this->queue);
        if ($next === null) {
            throw new \LogicException('No response queued for ' . $request->method . ' ' . $request->url);
        }
        if ($next instanceof \Throwable) {
            throw $next;
        }

        return $next;
    }

    public function last(): Request
    {
        return $this->requests[count($this->requests) - 1];
    }

    /**
     * @return array<string, list<string>>
     */
    public static function query(Request $request): array
    {
        $out = [];
        $query = (string) parse_url($request->url, PHP_URL_QUERY);
        if ($query === '') {
            return $out;
        }
        foreach (explode('&', $query) as $pair) {
            [$name, $value] = array_pad(explode('=', $pair, 2), 2, '');
            $out[rawurldecode($name)][] = rawurldecode($value);
        }

        return $out;
    }
}
