<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Http;

use Noosh24\OpenApi\Exception\ConnectionException;

final class CurlTransport implements Transport
{
    public function send(Request $request, float $timeout): Response
    {
        $handle = curl_init($request->url);
        if ($handle === false) {
            throw new ConnectionException('Could not start a cURL session');
        }
        $headers = [];
        foreach ($request->headers as $name => $value) {
            $headers[] = $name . ': ' . $value;
        }
        $received = [];
        curl_setopt_array($handle, [
            CURLOPT_CUSTOMREQUEST => $request->method,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_TIMEOUT_MS => (int) round($timeout * 1000),
            CURLOPT_CONNECTTIMEOUT_MS => (int) round(min($timeout, 10.0) * 1000),
            CURLOPT_HEADERFUNCTION => static function ($curl, string $line) use (&$received): int {
                $parts = explode(':', $line, 2);
                if (count($parts) === 2) {
                    $received[strtolower(trim($parts[0]))] = trim($parts[1]);
                }

                return strlen($line);
            },
        ]);
        if ($request->body !== null) {
            curl_setopt($handle, CURLOPT_POSTFIELDS, $request->body);
        }
        $body = curl_exec($handle);
        if ($body === false) {
            $message = curl_error($handle);
            $code = curl_errno($handle);
            throw new ConnectionException($message !== '' ? $message : 'Request failed', $code);
        }
        $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);

        return new Response($status, $received, (string) $body);
    }
}
