export type WhereValue = string | number | boolean | Date;

const fieldPattern = /^[A-Za-z][A-Za-z0-9_.]*$/;

export function literal(value: WhereValue): string {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      throw new TypeError('where got an invalid Date');
    }
    return `'${value.toISOString()}'`;
  }
  if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) {
      throw new TypeError('Numbers in where must be finite');
    }
    return String(value);
  }
  if (typeof value === 'string') {
    return `'${value.replace(/'/g, "''")}'`;
  }
  throw new TypeError('where takes strings, numbers, booleans and dates');
}

export class Where {
  private readonly conditions: string[] = [];

  eq(field: string, value: WhereValue): this {
    return this.add(field, '=', value);
  }

  ne(field: string, value: WhereValue): this {
    return this.add(field, '!=', value);
  }

  gt(field: string, value: WhereValue): this {
    return this.add(field, '>', value);
  }

  gte(field: string, value: WhereValue): this {
    return this.add(field, '>=', value);
  }

  lt(field: string, value: WhereValue): this {
    return this.add(field, '<', value);
  }

  lte(field: string, value: WhereValue): this {
    return this.add(field, '<=', value);
  }

  in(field: string, values: readonly WhereValue[]): this {
    if (values.length === 0) {
      throw new TypeError('in() needs at least one value');
    }
    this.conditions.push(`${checkField(field)} in (${values.map(literal).join(', ')})`);
    return this;
  }

  toString(): string {
    return this.conditions.join(' AND ');
  }

  private add(field: string, operator: string, value: WhereValue): this {
    this.conditions.push(`${checkField(field)} ${operator} ${literal(value)}`);
    return this;
  }
}

export function where(): Where {
  return new Where();
}

function checkField(field: string): string {
  if (!fieldPattern.test(field)) {
    throw new TypeError(`"${field}" is not a field name`);
  }
  return field;
}
