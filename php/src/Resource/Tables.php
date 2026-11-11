<?php

declare(strict_types=1);

namespace Noosh24\OpenApi\Resource;

use Noosh24\OpenApi\Model\Hall;
use Noosh24\OpenApi\Model\Table;

final class Tables extends Resource
{
    /**
     * @return list<Table>
     */
    public function list(): array
    {
        return $this->fetchAll('/tables', [Table::class, 'fromArray']);
    }

    /**
     * @return list<Hall>
     */
    public function listHalls(): array
    {
        return $this->fetchAll('/halls', [Hall::class, 'fromArray']);
    }
}
