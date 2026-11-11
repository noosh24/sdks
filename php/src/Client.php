<?php

declare(strict_types=1);

namespace Noosh24\OpenApi;

use Noosh24\OpenApi\Exception\ApiException;
use Noosh24\OpenApi\Exception\ConnectionException;
use Noosh24\OpenApi\Http\CurlTransport;
use Noosh24\OpenApi\Http\Request;
use Noosh24\OpenApi\Http\Response;
use Noosh24\OpenApi\Http\Transport;
use Noosh24\OpenApi\Model\Whoami;
use Noosh24\OpenApi\Resource\Customers;
use Noosh24\OpenApi\Resource\Loyalty;
use Noosh24\OpenApi\Resource\Menu;
use Noosh24\OpenApi\Resource\Orders;
use Noosh24\OpenApi\Resource\Payments;
use Noosh24\OpenApi\Resource\Reservations;
use Noosh24\OpenApi\Resource\Reviews;
use Noosh24\OpenApi\Resource\Stock;
use Noosh24\OpenApi\Resource\Tables;

final class Client
{
    public const VERSION = '0.1.0';

    public const DEFAULT_BASE_URL = 'https://open-api.noosh24.com/v1';

    private const RETRY_STATUSES = [429, 502, 503, 504];

    private const MAX_RETRY_WAIT = 60.0;

    public readonly Menu $menu;

    public readonly Reservations $reservations;

    public readonly Orders $orders;

    public readonly Payments $payments;

    public readonly Tables $tables;

    public readonly Customers $customers;

    public readonly Loyalty $loyalty;

    public readonly Stock $stock;

    public readonly Reviews $reviews;

    private readonly string $apiKey;

    private readonly string $baseUrl;

    private readonly float $timeout;

    private readonly int $maxRetries;

    private readonly Transport $transport;

    private readonly string $userAgent;

    private readonly \Closure $sleep;

    /**
     * @param array{baseUrl?: string, timeout?: float|int, maxRetries?: int, transport?: Transport, userAgent?: string, sleep?: callable(float): void} $options
     */
    public function __construct(string $apiKey, array $options = [])
    {
        $apiKey = trim($apiKey);
        if ($apiKey === '') {
            throw new \InvalidArgumentException('An API key is required');
        }
        $this->apiKey = $apiKey;
        $this->baseUrl = rtrim($options['baseUrl'] ?? self::DEFAULT_BASE_URL, '/');
        $this->timeout = (float) ($options['timeout'] ?? 30);
        $this->maxRetries = max(0, (int) ($options['maxRetries'] ?? 2));
        $this->transport = $options['transport'] ?? new CurlTransport();
        $agent = 'noosh24-php/' . self::VERSION . ' php/' . PHP_VERSION;
        $this->userAgent = isset($options['userAgent']) ? $options['userAgent'] . ' ' . $agent : $agent;
        $this->sleep = isset($options['sleep'])
            ? \Closure::fromCallable($options['sleep'])
            : static function (float $seconds): void {
                usleep((int) round($seconds * 1000000));
            };

        $this->menu = new Menu($this);
        $this->reservations = new Reservations($this);
        $this->orders = new Orders($this);
        $this->payments = new Payments($this);
        $this->tables = new Tables($this);
        $this->customers = new Customers($this);
        $this->loyalty = new Loyalty($this);
        $this->stock = new Stock($this);
        $this->reviews = new Reviews($this);
    }

    public function whoami(): Whoami
    {
        return Whoami::fromArray($this->request('GET', '/whoami')['data']);
    }

    /**
     * @internal
     * @param array<string, mixed> $query
     * @param array<string, mixed>|null $body
     * @return array{status: int, data: mixed}
     */
    public function request(string $method, string $path, array $query = [], ?array $body = null, bool $retryable = true): array
    {
        $url = $this->baseUrl . $path;
        $queryString = self::buildQuery($query);
        if ($queryString !== '') {
            $url .= '?' . $queryString;
        }
        $headers = [
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Accept' => 'application/json',
            'User-Agent' => $this->userAgent,
        ];
        $payload = null;
        if ($body !== null) {
            $headers['Content-Type'] = 'application/json';
            $payload = json_encode($body === [] ? new \stdClass() : $body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
        }
        $request = new Request($method, $url, $headers, $payload);

        $attempt = 0;
        while (true) {
            try {
                $response = $this->transport->send($request, $this->timeout);
            } catch (ConnectionException $e) {
                if (!$retryable || $attempt >= $this->maxRetries) {
                    throw $e;
                }
                ($this->sleep)($this->backoff($attempt));
                $attempt++;
                continue;
            }
            if ($response->status >= 200 && $response->status < 300) {
                return ['status' => $response->status, 'data' => self::decode($response)];
            }
            $wait = $this->retryWait($response, $attempt);
            if ($retryable && $attempt < $this->maxRetries && $wait !== null) {
                ($this->sleep)($wait);
                $attempt++;
                continue;
            }
            throw ApiException::fromResponse($response->status, $response->headers, $response->body);
        }
    }

    /**
     * @param array<string, mixed> $query
     */
    public static function buildQuery(array $query): string
    {
        $parts = [];
        foreach ($query as $name => $value) {
            if ($value === null) {
                continue;
            }
            foreach (is_array($value) ? $value : [$value] as $item) {
                if ($item === null) {
                    continue;
                }
                if (is_bool($item)) {
                    $item = $item ? 'true' : 'false';
                } elseif ($item instanceof \DateTimeInterface) {
                    $item = $item->format('Y-m-d');
                }
                $parts[] = rawurlencode((string) $name) . '=' . rawurlencode((string) $item);
            }
        }

        return implode('&', $parts);
    }

    private static function decode(Response $response): mixed
    {
        if ($response->body === '') {
            return null;
        }
        try {
            $decoded = json_decode($response->body, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
            throw new ApiException($response->status, null, 'The API answered with a body that is not JSON', $response->headers, $response->body);
        }
        if (!is_array($decoded) || !array_key_exists('data', $decoded)) {
            throw new ApiException($response->status, null, 'The API answered without a "data" field', $response->headers, $response->body);
        }

        return $decoded['data'];
    }

    private function retryWait(Response $response, int $attempt): ?float
    {
        if (!in_array($response->status, self::RETRY_STATUSES, true)) {
            return null;
        }
        $header = $response->header('retry-after');
        if ($header !== null && is_numeric($header)) {
            $wait = max(0.0, (float) $header);

            return $wait <= self::MAX_RETRY_WAIT ? $wait : null;
        }

        return $this->backoff($attempt);
    }

    private function backoff(int $attempt): float
    {
        return min(8.0, 0.5 * (2 ** $attempt));
    }
}
