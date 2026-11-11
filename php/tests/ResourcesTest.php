<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Tests;

use Noosh24\OpenApi\Exception\ServerException;
use Noosh24\OpenApi\Exception\TableTakenException;
use Noosh24\OpenApi\Model\Product;
use Noosh24\OpenApi\Where;

final class ResourcesTest extends TestCase
{
    private const PRODUCT = [
        'id' => '0b6f3c1e', 'name' => 'Plov', 'category' => 'Main', 'description' => 'Saffron rice with lamb',
        'price' => 14, 'available' => true, 'popular' => true, 'position' => 3, 'prepMinutes' => 20,
        'station' => '', 'vatRate' => null, 'vegetarian' => false, 'spicy' => false, 'allergens' => ['gluten'],
        'discountable' => true, 'hasModifiers' => true, 'image' => 'https://api.noosh24.com/m/5c1d.jpg', 'video' => null,
        'modifierGroups' => [['id' => 'g1', 'name' => 'Size', 'required' => true, 'position' => 0, 'modifiers' => [
            ['id' => 'm1', 'name' => 'Large', 'priceDelta' => 2.5, 'position' => 0],
        ]]],
        'translations' => ['en' => ['name' => 'Pilaf', 'description' => 'Rice'], 'ru' => ['name' => 'Плов']],
    ];

    private const RESERVATION = [
        'id' => 'res1', 'code' => 'K7Q2', 'status' => 'pending', 'source' => 'open_api',
        'startsAt' => '2026-11-20T15:30:00Z', 'endsAt' => '2026-11-20T17:30:00.123456789Z', 'guests' => 4, 'zone' => 'Terrace',
        'table' => ['id' => 't5', 'label' => 'T5'], 'guest' => ['name' => 'Aysel', 'phone' => '+994501234567', 'email' => null],
        'specialRequest' => null, 'allergyNote' => null, 'birthday' => false, 'childChair' => true, 'depositPaid' => 0,
        'preOrder' => [['productId' => 'p1', 'name' => 'Plov', 'price' => 14.5, 'qty' => 2, 'note' => null]],
        'externalRef' => 'acme-991', 'decidedAt' => null, 'createdAt' => '2026-11-11T10:00:00Z', 'updatedAt' => '2026-11-11T10:00:00Z',
    ];

    public function testListProductsSendsListParametersAndParsesThePage(): void
    {
        $client = $this->client();
        $this->http->json(200, self::page([self::PRODUCT], 87, 50, 50));

        $page = $client->menu->listProducts([
            'limit' => 50,
            'offset' => 50,
            'sort' => ['category asc', 'price desc'],
            'where' => Where::create()->eq('category', "Chef's")->gte('price', 5)->eq('available', true),
            'expand' => ['modifierGroups', 'translations'],
        ]);

        $request = $this->http->last();
        self::assertSame('/v1/menu/products', parse_url($request->url, PHP_URL_PATH));
        self::assertSame([
            'limit' => ['50'],
            'offset' => ['50'],
            'sort' => ['category asc', 'price desc'],
            'where' => ["category = 'Chef''s' AND price >= 5 AND available = true"],
            'expand' => ['modifierGroups', 'translations'],
        ], MockTransport::query($request));

        self::assertSame(87, $page->total);
        self::assertSame(50, $page->limit);
        self::assertSame(50, $page->offset);
        self::assertTrue($page->hasMore());
        self::assertCount(1, $page);
        $product = $page->items[0];
        self::assertInstanceOf(Product::class, $product);
        self::assertSame(14.0, $product->price);
        self::assertNull($product->vatRate);
        self::assertNull($product->video);
        self::assertSame(['gluten'], $product->allergens);
        self::assertSame(2.5, $product->modifierGroups[0]->modifiers[0]->priceDelta);
        self::assertSame('Pilaf', $product->translations['en']->name);
        self::assertNull($product->translations['ru']->description);
        self::assertSame(self::PRODUCT, $product->toArray());
        self::assertSame(self::PRODUCT, json_decode((string) json_encode($product), true));
    }

    public function testListAcceptsAPlainWhereAndSortString(): void
    {
        $client = $this->client();
        $this->http->json(200, self::page([], 0));

        $client->orders->list(['where' => "status = 'served'", 'sort' => 'createdAt desc']);

        self::assertSame(['sort' => ['createdAt desc'], 'where' => ["status = 'served'"]], MockTransport::query($this->http->last()));
    }

    public function testUnknownListParameterIsRejected(): void
    {
        $client = $this->client();

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('page');
        $client->reviews->list(['page' => 2]);
    }

    public function testIteratorWalksEveryPage(): void
    {
        $client = $this->client();
        $this->http
            ->json(200, self::page([['id' => 'c1'], ['id' => 'c2']], 5, 2, 0))
            ->json(200, self::page([['id' => 'c3'], ['id' => 'c4']], 5, 2, 2))
            ->json(200, self::page([['id' => 'c5']], 5, 2, 4));

        $ids = [];
        foreach ($client->customers->iterate(['limit' => 2, 'where' => "createdAt >= '2026-11-01'"]) as $customer) {
            $ids[] = $customer->id;
        }

        self::assertSame(['c1', 'c2', 'c3', 'c4', 'c5'], $ids);
        self::assertCount(3, $this->http->requests);
        self::assertSame(['0', '2', '4'], array_map(static fn ($r) => MockTransport::query($r)['offset'][0], $this->http->requests));
        self::assertSame(["createdAt >= '2026-11-01'"], MockTransport::query($this->http->requests[2])['where']);
    }

    public function testIteratorStopsOnAnEmptyPage(): void
    {
        $client = $this->client();
        $this->http->json(200, self::page([], 10, 100, 0));

        self::assertSame([], iterator_to_array($client->payments->iterate()));
        self::assertCount(1, $this->http->requests);
    }

    public function testIteratorUsesTheLargestPageEachEndpointAllows(): void
    {
        $client = $this->client();
        $this->http->json(200, self::page([], 0))->json(200, self::page([], 0))->json(200, self::page([], 0));

        iterator_to_array($client->orders->iterateBills());
        iterator_to_array($client->menu->iterateProducts(['expand' => 'modifierGroups']));
        iterator_to_array($client->stock->iterateMoves());

        self::assertSame(['50', '50', '100'], array_map(static fn ($r) => MockTransport::query($r)['limit'][0], $this->http->requests));
    }

    public function testGetProductEncodesTheIdAndExpand(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => self::PRODUCT]);

        $product = $client->menu->getProduct('a/b c', 'translations');

        self::assertSame('https://open-api.noosh24.com/v1/menu/products/a%2Fb%20c?expand=translations', $this->http->last()->url);
        self::assertSame('Plov', $product->name);
    }

    public function testEmptyIdIsRejected(): void
    {
        $client = $this->client();

        $this->expectException(\InvalidArgumentException::class);
        $client->orders->get('');
    }

    public function testCategoriesAndStopList(): void
    {
        $client = $this->client();
        $this->http
            ->json(200, ['data' => ['items' => [['name' => 'Salads', 'position' => 1, 'products' => 9, 'available' => 8]], 'total' => 1]])
            ->json(200, ['data' => ['items' => [['id' => 'p9', 'name' => 'Dolma', 'category' => 'Main', 'price' => 9.5]], 'total' => 1]]);

        $categories = $client->menu->listCategories();
        $stop = $client->menu->getStopList();

        self::assertSame(8, $categories[0]->available);
        self::assertSame('Dolma', $stop[0]->name);
        self::assertStringEndsWith('/v1/menu/stop-list', $this->http->last()->url);
    }

    public function testReservationParsesNestedFieldsAndTimes(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => self::RESERVATION]);

        $reservation = $client->reservations->get('res1');

        self::assertSame('2026-11-20T15:30:00+00:00', $reservation->startsAt->format(DATE_ATOM));
        self::assertSame('2026-11-20 17:30:00.123456', $reservation->endsAt->format('Y-m-d H:i:s.u'));
        self::assertNull($reservation->decidedAt);
        self::assertSame('T5', $reservation->table->label);
        self::assertSame('+994501234567', $reservation->guest->phone);
        self::assertNull($reservation->guest->email);
        self::assertSame(2, $reservation->preOrder[0]->qty);
        self::assertSame(0.0, $reservation->depositPaid);
    }

    public function testAvailability(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => [
            'startsAt' => '2026-11-20T15:30:00Z', 'endsAt' => '2026-11-20T17:30:00Z', 'durationMinutes' => 120,
            'openTime' => '10:00', 'closeTime' => '23:00',
            'tables' => [['id' => 't5', 'label' => 'T5', 'hallId' => 'h1', 'zone' => 'Terrace', 'seats' => 4, 'free' => true]],
        ]]);

        $availability = $client->reservations->availability(new \DateTimeImmutable('2026-11-20'), '19:30', 4);

        self::assertSame(['date' => ['2026-11-20'], 'time' => ['19:30'], 'guests' => ['4']], MockTransport::query($this->http->last()));
        self::assertSame(120, $availability->durationMinutes);
        self::assertTrue($availability->tables[0]->free);
    }

    public function testCreateReservationPostsJsonAndReportsCreated(): void
    {
        $client = $this->client();
        $this->http->json(201, ['data' => self::RESERVATION]);

        $result = $client->reservations->create([
            'date' => new \DateTimeImmutable('2026-11-20'),
            'time' => '19:30',
            'guests' => 4,
            'guestName' => 'Aysel Məmmədova',
            'phone' => '+994501234567',
            'preOrder' => [['itemId' => 'p1', 'qty' => 2]],
            'externalRef' => 'acme-991',
        ]);

        $request = $this->http->last();
        self::assertSame('POST', $request->method);
        self::assertStringEndsWith('/v1/reservations', $request->url);
        self::assertSame('application/json', $request->headers['Content-Type']);
        self::assertSame([
            'date' => '2026-11-20', 'time' => '19:30', 'guests' => 4, 'guestName' => 'Aysel Məmmədova',
            'phone' => '+994501234567', 'preOrder' => [['itemId' => 'p1', 'qty' => 2]], 'externalRef' => 'acme-991',
        ], json_decode((string) $request->body, true));
        self::assertStringContainsString('Məmmədova', (string) $request->body);
        self::assertTrue($result->created);
        self::assertSame('K7Q2', $result->reservation->code);
    }

    public function testCreateReservationWithAKnownExternalRefReturnsTheExistingBooking(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => self::RESERVATION]);

        $result = $client->reservations->create(['date' => '2026-11-20', 'time' => '19:30', 'guests' => 4, 'guestName' => 'Aysel', 'phone' => '+994501234567', 'externalRef' => 'acme-991']);

        self::assertFalse($result->created);
        self::assertSame('res1', $result->reservation->id);
    }

    public function testCreateWithExternalRefIsRetried(): void
    {
        $client = $this->client();
        $this->http
            ->json(503, ['error' => 'temporarily_unavailable'], ['Retry-After' => '0'])
            ->json(201, ['data' => self::RESERVATION]);

        $result = $client->reservations->create(['date' => '2026-11-20', 'time' => '19:30', 'guests' => 4, 'guestName' => 'Aysel', 'phone' => '+994501234567', 'externalRef' => 'acme-991']);

        self::assertTrue($result->created);
        self::assertCount(2, $this->http->requests);
        self::assertSame($this->http->requests[0]->body, $this->http->requests[1]->body);
    }

    public function testCreateWithoutExternalRefIsNeverRetried(): void
    {
        $client = $this->client();
        $this->http->json(503, ['error' => 'temporarily_unavailable'], ['Retry-After' => '0']);

        $this->expectException(ServerException::class);
        try {
            $client->reservations->create(['date' => '2026-11-20', 'time' => '19:30', 'guests' => 4, 'guestName' => 'Aysel', 'phone' => '+994501234567']);
        } finally {
            self::assertCount(1, $this->http->requests);
        }
    }

    public function testTableTaken(): void
    {
        $client = $this->client();
        $this->http->json(409, ['error' => 'table_taken', 'message' => 'Bu masa seçilən vaxt üçün artıq tutulub']);

        $this->expectException(TableTakenException::class);
        $this->expectExceptionMessage('Bu masa seçilən vaxt üçün artıq tutulub');
        $client->reservations->create(['date' => '2026-11-20', 'time' => '19:30', 'guests' => 4, 'guestName' => 'Aysel', 'phone' => '+994501234567', 'tableId' => 't5', 'externalRef' => 'x']);
    }

    public function testCancel(): void
    {
        $client = $this->client();
        $this->http->json(200, ['data' => ['status' => 'cancelled'] + self::RESERVATION]);

        $reservation = $client->reservations->cancel('res1');

        self::assertSame('POST', $this->http->last()->method);
        self::assertSame('https://open-api.noosh24.com/v1/reservations/res1/cancel', $this->http->last()->url);
        self::assertNull($this->http->last()->body);
        self::assertSame('cancelled', $reservation->status);
    }

    public function testOrdersAndBills(): void
    {
        $client = $this->client();
        $this->http
            ->json(200, ['data' => [
                'id' => 'o1', 'number' => 'A-12', 'dailyNumber' => 12, 'kind' => 'delivery', 'orderType' => null, 'status' => 'ready',
                'tableId' => '', 'billId' => '', 'customerName' => null, 'allergyNote' => null, 'subtotal' => 30,
                'items' => [['id' => 'i1', 'productId' => 'p1', 'name' => 'Plov', 'qty' => 2, 'price' => 15, 'listPrice' => null, 'modifiers' => null, 'note' => null, 'status' => 'ready', 'comp' => false, 'campaign' => null, 'cancelReason' => null]],
                'delivery' => ['status' => 'accepted', 'platform' => ['id' => 'wolt', 'name' => 'Wolt', 'ref' => 'W-1'], 'fee' => 2, 'acceptedAt' => '2026-11-11T09:00:00Z'],
                'createdAt' => '2026-11-11T08:55:00Z', 'updatedAt' => '2026-11-11T09:00:00Z',
            ]])
            ->json(200, ['data' => ['id' => 'b1', 'status' => 'paid', 'orderIds' => ['o1', 'o2'], 'total' => 45.5, 'closedAt' => null, 'openedAt' => '2026-11-11T08:00:00Z']]);

        $order = $client->orders->get('o1');
        $bill = $client->orders->getBill('b1');

        self::assertSame('Wolt', $order->delivery->platform->name);
        self::assertSame(2.0, $order->delivery->fee);
        self::assertSame(15.0, $order->items[0]->price);
        self::assertSame(['o1', 'o2'], $bill->orderIds);
        self::assertSame(45.5, $bill->total);
        self::assertNull($bill->closedAt);
        self::assertStringEndsWith('/v1/bills/b1', $this->http->last()->url);
    }

    public function testPaymentsAndZReport(): void
    {
        $client = $this->client();
        $this->http
            ->json(200, ['data' => ['id' => 'pay1', 'method' => 'card', 'amount' => 20, 'card' => ['maskedPan' => '4169********1234', 'scheme' => 'visa', 'bank' => 'Kapital'], 'platform' => null]])
            ->json(200, ['data' => ['date' => '2026-11-10', 'cash' => 120.5, 'card' => 300]]);

        $payment = $client->payments->get('pay1');
        $z = $client->payments->zReport('2026-11-10');

        self::assertSame('visa', $payment->card->scheme);
        self::assertNull($payment->platform);
        self::assertSame(['date' => ['2026-11-10']], MockTransport::query($this->http->last()));
        self::assertSame(120.5, $z['cash']);
    }

    public function testTablesLoyaltyStockAndReviews(): void
    {
        $client = $this->client();
        $this->http
            ->json(200, ['data' => ['items' => [['id' => 't1', 'label' => 'T1', 'status' => 'occupied', 'guests' => 3, 'billTotal' => 42.1, 'billRequested' => false]], 'total' => 1]])
            ->json(200, ['data' => ['stampsNeeded' => 8, 'earnBy' => 'visit', 'rewardProductIds' => ['p1']]])
            ->json(200, self::page([['id' => 'card1', 'stamps' => 5, 'lastVisitAt' => null]], 1, 100))
            ->json(200, self::page([['id' => 'ing1', 'name' => 'Rice', 'stock' => 12, 'byStore' => ['s1' => 10, 's2' => 2.5], 'state' => 'ok']], 1))
            ->json(200, ['data' => ['items' => [['id' => 's1', 'name' => 'Main', 'isDefault' => true, 'stations' => ['hot']]], 'total' => 1]])
            ->json(200, self::page([['id' => 'rv1', 'overall' => 4.5, 'ratings' => ['food' => 5, 'service' => 4, 'atmosphere' => 4, 'cleanliness' => 5, 'price' => 4], 'reply' => null]], 1));

        $tables = $client->tables->list();
        $program = $client->loyalty->getProgram();
        $cards = $client->loyalty->listCards();
        $ingredients = $client->stock->listIngredients();
        $stores = $client->stock->listStores();
        $reviews = $client->reviews->list();

        self::assertSame(42.1, $tables[0]->billTotal);
        self::assertSame(8, $program->stampsNeeded);
        self::assertSame(5, $cards->items[0]->stamps);
        self::assertFalse($cards->hasMore());
        self::assertSame(['s1' => 10.0, 's2' => 2.5], $ingredients->items[0]->byStore);
        self::assertTrue($stores[0]->isDefault);
        self::assertSame(5.0, $reviews->items[0]->ratings->food);
        self::assertSame(
            ['/v1/tables', '/v1/loyalty/program', '/v1/loyalty/cards', '/v1/stock/ingredients', '/v1/stock/stores', '/v1/reviews'],
            array_map(static fn ($r) => parse_url($r->url, PHP_URL_PATH), $this->http->requests)
        );
    }

    public function testModelsTolerateMissingAndUnknownFields(): void
    {
        $client = $this->client();
        $this->http->json(201, ['data' => ['id' => 'res9', 'code' => 'ZZ11', 'status' => 'pending', 'brandNew' => 1]]);

        $result = $client->reservations->create(['date' => '2026-11-20', 'time' => '19:30', 'guests' => 2, 'guestName' => 'A', 'phone' => '+994501234567']);

        self::assertSame('ZZ11', $result->reservation->code);
        self::assertNull($result->reservation->guest);
        self::assertNull($result->reservation->preOrder);
        self::assertSame(1, $result->reservation->toArray()['brandNew']);
    }
}
