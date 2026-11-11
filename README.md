# Noosh24 Open API SDKs

Official clients for the [Noosh24 Open API](https://developer.noosh24.com).

| Language | Folder | Package | Runtime |
| --- | --- | --- | --- |
| PHP | [`php/`](php) | `noosh24/open-api` (Packagist) | PHP 7.4+, ext-curl |
| Node.js / TypeScript | [`node/`](node) | `@noosh24/open-api` (npm) | Node.js 18+ |
| Python | [`python/`](python) | `noosh24` (PyPI) | Python 3.8+, httpx |

All three share one shape: a client built from the venue's API key, one resource group per API tag (`menu`, `reservations`, `orders`, `payments`, `tables`, `customers`, `loyalty`, `stock`, `reviews`, plus `whoami()`), typed models, list methods with `limit`/`offset`/`sort`/`where`/`expand`, an auto-paginating iterator, a `where` builder, reservation create/cancel with `externalRef` idempotency, retries on `429`/`503` that honour `Retry-After`, and one error class per API `error` code.

## Spec

`spec/openapi.json` is the copy of https://developer.noosh24.com/openapi.json the SDKs were built against (API version 1.1.0). The models in all three SDKs come from `tools/gen_models.py`; after a spec change, update the table there and run:

```bash
python3 tools/gen_models.py
```

## Tests

```bash
cd php && composer install && composer test
cd node && npm install && npm test
cd python && python3 -m venv .venv && .venv/bin/pip install -e '.[dev]' && .venv/bin/pytest
```

## Releasing

Each SDK is versioned and released on its own; bump the version in the files below first.

- PHP: the version lives in `php/src/Client.php` (`VERSION`). Packagist reads a Git repository whose root holds `composer.json`, so either publish `php/` as its own repository (for example a read-only split `noosh24/open-api-php`) or move this monorepo's PHP package to the root of a dedicated repository. Submit that repository URL at https://packagist.org/packages/submit under a `noosh24` vendor account, add the GitHub hook, and tag `v0.1.0`.
- Node.js: the version lives in `node/package.json` and `node/src/version.ts`. Create the `noosh24` organisation on npmjs.com, then `cd node && npm publish --access public` (`prepublishOnly` runs the type check, tests and build).
- Python: the version lives in `python/src/noosh24/_version.py`. Create the `noosh24` project on PyPI with a scoped API token, then `cd python && python -m build && python -m twine upload dist/*`.

## License

MIT
