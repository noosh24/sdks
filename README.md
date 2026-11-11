<div align="center">

<a href="https://developer.noosh24.com"><img src="https://raw.githubusercontent.com/noosh24/sdks/main/.github/assets/noosh-lockup.svg" alt="Noosh24" width="360"></a>

# Noosh24 Open API SDKs

**Official clients for the [Noosh24 Open API](https://developer.noosh24.com).**<br>
Connect delivery aggregators, accounting, loyalty, digital signage and BI to a Noosh24 restaurant in a few lines.

<img src="https://img.shields.io/badge/Open%20API-1.1.0-DC4A38" alt="API 1.1.0"> <img src="https://img.shields.io/badge/SDKs-9%20languages-555555" alt="9 languages"> <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license"></a>

[Developer site](https://developer.noosh24.com) · [API reference](https://developer.noosh24.com/reference) · [OpenAPI spec](spec/openapi.json) · [Report an issue](https://github.com/noosh24/sdks/issues)

</div>

## Languages

| Language | Package | Registry | Runtime | Tests |
| --- | --- | --- | --- | --- |
| [PHP](php) | `noosh24/open-api` | Packagist | PHP 8.2+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/php.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/php.yml) |
| [Node.js / TypeScript](node) | `@noosh24/open-api` | npm | Node.js 22+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/node.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/node.yml) |
| [Python](python) | `noosh24` | PyPI | Python 3.11+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/python.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/python.yml) |
| [C# / .NET](dotnet) | `Noosh24.OpenApi` | NuGet | .NET 10+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/dotnet.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/dotnet.yml) |
| [Java / Kotlin](java) | `com.noosh24:noosh24-open-api` | Maven Central | Java 21+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/java.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/java.yml) |
| [Go](go) | `github.com/noosh24/noosh24-go` | Go modules | Go 1.26+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/go.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/go.yml) |
| [Ruby](ruby) | `noosh24` | RubyGems | Ruby 3.3+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/ruby.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/ruby.yml) |
| [Dart](dart) | `noosh24` | pub.dev | Dart 3.11+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/dart.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/dart.yml) |
| [Swift](swift) | `Noosh24` | SwiftPM | Swift 6.0+ | [![CI](https://github.com/noosh24/sdks/actions/workflows/swift.yml/badge.svg)](https://github.com/noosh24/sdks/actions/workflows/swift.yml) |

## Quick start

Get an API key for your venue from Noosh24, put it in `NOOSH24_API_KEY`, and pick your language:

<details>
<summary><b>PHP</b> · <code>composer require noosh24/open-api</code></summary>

```bash
composer require noosh24/open-api
```

```php
<?php

require 'vendor/autoload.php';

use Noosh24\OpenApi\Client;
use Noosh24\OpenApi\Where;

$noosh = new Client(getenv('NOOSH24_API_KEY'));

$me = $noosh->whoami();
echo $me->restaurant->name, PHP_EOL;
print_r($me->key->scopes);

$page = $noosh->menu->listProducts([
    'where' => Where::create()->eq('category', 'Salads')->eq('available', true),
    'sort' => 'price desc',
    'limit' => 50,
]);
foreach ($page as $product) {
    printf("%s  %.2f AZN\n", $product->name, $product->price);
}
echo $page->total, ' products match', PHP_EOL;
```

More in the [PHP README](php/README.md).

</details>
<details>
<summary><b>Node.js / TypeScript</b> · <code>npm install @noosh24/open-api</code></summary>

```bash
npm install @noosh24/open-api
```

```ts
import { Noosh24, where } from '@noosh24/open-api';

const noosh = new Noosh24(process.env.NOOSH24_API_KEY!);

const me = await noosh.whoami();
console.log(me.restaurant.name, me.key.scopes);

const page = await noosh.menu.listProducts({
  where: where().eq('category', 'Salads').eq('available', true),
  sort: 'price desc',
  limit: 50,
});
for (const product of page.items) {
  console.log(product.name, product.price);
}
console.log(`${page.total} products match`);
```

More in the [Node.js / TypeScript README](node/README.md).

</details>
<details>
<summary><b>Python</b> · <code>pip install noosh24</code></summary>

```bash
pip install noosh24
```

```python
import os

from noosh24 import Noosh24, where

noosh = Noosh24(os.environ["NOOSH24_API_KEY"])

me = noosh.whoami()
print(me.restaurant.name, me.key.scopes)

page = noosh.menu.list_products(
    where=where().eq("category", "Salads").eq("available", True),
    sort="price desc",
    limit=50,
)
for product in page:
    print(product.name, product.price)
print(page.total, "products match")
```

More in the [Python README](python/README.md).

</details>
<details>
<summary><b>C# / .NET</b> · <code>dotnet add package Noosh24.OpenApi</code></summary>

```bash
dotnet add package Noosh24.OpenApi
```

```csharp
using Noosh24.OpenApi;

using var noosh = new Noosh24Client(Environment.GetEnvironmentVariable("NOOSH24_API_KEY")!);

var me = await noosh.WhoamiAsync();
Console.WriteLine($"{me.Restaurant?.Name} {string.Join(", ", me.Key?.Scopes ?? [])}");

var page = await noosh.Menu.ListProductsAsync(new ProductListOptions
{
    Where = new Where().Eq("category", "Salads").Eq("available", true),
    Sort = ["price desc"],
    Limit = 50,
});
foreach (var product in page)
{
    Console.WriteLine($"{product.Name} {product.Price}");
}
Console.WriteLine($"{page.Total} products match");
```

More in the [C# / .NET README](dotnet/README.md).

</details>
<details>
<summary><b>Java / Kotlin</b> · <code>implementation("com.noosh24:noosh24-open-api:0.1.0")</code></summary>

```kotlin
implementation("com.noosh24:noosh24-open-api:0.1.0")
```

```java
import static com.noosh24.openapi.Where.where;

import com.noosh24.openapi.Noosh24Client;
import com.noosh24.openapi.Page;
import com.noosh24.openapi.ProductListParams;
import com.noosh24.openapi.model.Product;
import com.noosh24.openapi.model.Whoami;

try (Noosh24Client noosh = new Noosh24Client(System.getenv("NOOSH24_API_KEY"))) {
    Whoami me = noosh.whoami();
    System.out.println(me.restaurant().name() + " " + me.key().scopes());

    Page<Product> page = noosh.menu().listProducts(ProductListParams.builder()
            .where(where().eq("category", "Salads").eq("available", true))
            .sort("price desc")
            .limit(50)
            .build());
    for (Product product : page) {
        System.out.println(product.name() + " " + product.price());
    }
    System.out.println(page.total() + " products match");
}
```

More in the [Java / Kotlin README](java/README.md).

</details>
<details>
<summary><b>Go</b> · <code>go get github.com/noosh24/noosh24-go</code></summary>

```bash
go get github.com/noosh24/noosh24-go
```

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/noosh24/noosh24-go"
)

func main() {
	ctx := context.Background()
	client, err := noosh24.NewClient(os.Getenv("NOOSH24_API_KEY"))
	if err != nil {
		log.Fatal(err)
	}

	me, err := client.Whoami(ctx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(me.Restaurant.Name, me.Key.Scopes)

	page, err := client.Menu.ListProducts(ctx, &noosh24.ListParams{
		Where: noosh24.NewWhere().Eq("category", "Salads").Eq("available", true),
		Sort:  []string{"price desc"},
		Limit: 50,
	})
	if err != nil {
		log.Fatal(err)
	}
	for _, product := range page.Items {
		fmt.Println(product.Name, product.Price)
	}
	fmt.Println(page.Total, "products match")
}
```

More in the [Go README](go/README.md).

</details>
<details>
<summary><b>Ruby</b> · <code>gem install noosh24</code></summary>

```bash
gem install noosh24
```

```ruby
require "noosh24"

noosh = Noosh24::Client.new(ENV.fetch("NOOSH24_API_KEY"))

me = noosh.whoami
puts me.restaurant.name, me.key.scopes.inspect

page = noosh.menu.list_products(
  where: Noosh24.where.eq("category", "Salads").eq("available", true),
  sort: "price desc",
  limit: 50
)
page.each { |product| puts "#{product.name} #{product.price}" }
puts "#{page.total} products match"
```

More in the [Ruby README](ruby/README.md).

</details>
<details>
<summary><b>Dart</b> · <code>dart pub add noosh24</code></summary>

```bash
dart pub add noosh24
```

```dart
import 'dart:io';

import 'package:noosh24/noosh24.dart';

Future<void> main() async {
  final noosh = Noosh24Client(Platform.environment['NOOSH24_API_KEY']!);

  final me = await noosh.whoami();
  print('${me.restaurant?.name} ${me.key?.scopes}');

  final page = await noosh.menu.listProducts(
    where: Where().eq('category', 'Salads').eq('available', true),
    sort: 'price desc',
    limit: 50,
  );
  for (final product in page.items) {
    print('${product.name} ${product.price}');
  }
  print('${page.total} products match');

  noosh.close();
}
```

More in the [Dart README](dart/README.md).

</details>
<details>
<summary><b>Swift</b> · <code>.package(url: "https://github.com/noosh24/noosh24-swift.git", from: "0.1.0")</code></summary>

```swift
.package(url: "https://github.com/noosh24/noosh24-swift.git", from: "0.1.0")
```

```swift
import Foundation
import Noosh24

let noosh = try Noosh24Client(apiKey: ProcessInfo.processInfo.environment["NOOSH24_API_KEY"] ?? "")

let me = try await noosh.whoami()
print(me.restaurant?.name ?? "", me.key?.scopes ?? [])

let page = try await noosh.menu.listProducts(
    limit: 50,
    sort: "price desc",
    where: try Where().eq("category", "Salads").eq("available", true)
)
for product in page {
    print(product.name ?? "", product.price ?? 0)
}
print(page.total, "products match")
```

More in the [Swift README](swift/README.md).

</details>

> [!IMPORTANT]
> **Keep the API key on your server.** A key belongs to one venue and opens its data: guests' phone numbers, payments, and writing reservations. Never put it in a browser, a mobile app or a public repository. Mobile and web apps call your own backend, and your backend uses an SDK.

## What every SDK gives you

- **One client, one key.** Build it with the venue's API key; an optional base URL, timeout, retry count and user agent. `whoami` shows the venue, the key's scopes and the venue's modules.
- **Every resource.** `menu`, `reservations`, `orders` and bills, `payments` and the Z-report, `tables` and halls, `customers`, `loyalty`, `stock` and `reviews`, named after the API's tags.
- **Typed models.** Every response is a typed object in the language's own style, with timestamps as native date-times and money in AZN.
- **Lists that page themselves.** `limit`, `offset`, `sort`, `where` and `expand` on every list, a page with `total` and `hasMore`, and an iterator that walks every page on demand.
- **A safe `where` builder.** AND-only conditions with strings, dates and numbers quoted the way the API expects (`'Chef''s'`).
- **Idempotent reservations.** `create` with your own `externalRef` returns the existing booking on a repeat instead of making a second one, and tells you which it was. `cancel` is safe to repeat.
- **Typed errors.** One error type per API code, under status-level parents, so code can catch `TableTaken` or every `PermissionDenied` at once.
- **Retries done right.** `429`, `502`, `503`, `504` and network errors are retried with `Retry-After` or exponential backoff, never more than 60 seconds, and never for a create without an `externalRef`.

## Errors

| HTTP | `error` | Meaning |
| --- | --- | --- |
| 400 | `validation_error` | A parameter is wrong, for example a field that cannot be filtered. |
| 401 | `no_api_key`, `invalid_api_key` | No key, or a wrong or revoked one. |
| 403 | `insufficient_scope` | The key lacks the scope the endpoint needs. |
| 403 | `module_not_enabled` | The venue does not have the loyalty or inventory module. |
| 403 | `venue_suspended` | The venue is suspended. |
| 403 | `not_your_reservation` | The booking was not made through this API. |
| 404 | `not_found`, `table_not_found` | No such row in this venue. |
| 409 | `table_taken` | The table is already held for that time. |
| 409 | `cannot_cancel` | The guest is seated or the booking is over. |
| 422 | `outside_hours`, `in_the_past`, `table_too_small` | The booking cannot be made as asked. |
| 429 | `rate_limit_exceeded` | Too many requests: 600 a minute per key. Wait `Retry-After` seconds. |
| 503 | `temporarily_unavailable` | Try again. |

## Repository layout

```text
php/       PHP SDK
node/      Node.js / TypeScript SDK
python/    Python SDK
dotnet/    C# / .NET SDK
java/      Java / Kotlin SDK
go/        Go SDK
ruby/      Ruby SDK
dart/      Dart SDK
swift/     Swift SDK
spec/      openapi.json the SDKs are built against (API 1.1.0)
tools/     model generators and this README generator
```

The models in every SDK come from one table in `tools/gen_models.py` and a generator per language (`tools/gen_<lang>.py`). After a spec change, update the table and regenerate. These READMEs are kept in one style by `python3 tools/readme.py`.

## Versioning and releases

Each SDK has its own version and its own tag, `<folder>/v<version>` (for example `php/v0.1.0`). PHP, Go and Swift are mirrored to [noosh24-php](https://github.com/noosh24/noosh24-php), [noosh24-go](https://github.com/noosh24/noosh24-go) and [noosh24-swift](https://github.com/noosh24/noosh24-swift), because Packagist, Go modules and SwiftPM read a package from the repository root; open issues and pull requests here. [RELEASING.md](RELEASING.md) has the steps and the one-time registry setup.

Every SDK supports the runtime versions its upstream still maintains and is tested on the oldest and the newest of them.

## Contributing

Issues and pull requests are welcome. Each SDK's README ends with a Development section that shows how to run its tests; CI runs them on every supported runtime.

## License

[MIT](LICENSE) © Noosh24
