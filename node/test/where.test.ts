import { describe, expect, it } from 'vitest';
import { Where, literal, where } from '../src/index.js';

describe('where', () => {
  it('builds AND-only conditions', () => {
    const text = where()
      .eq('category', 'Salads')
      .ne('station', '')
      .gt('price', 4.75)
      .lte('prepMinutes', 15)
      .eq('vegetarian', false)
      .gte('createdAt', new Date('2026-11-01T14:00:00Z'))
      .lt('price', 20)
      .in('id', ['7f0c', "O'Neil", 3])
      .toString();

    expect(text).toBe(
      "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false" +
        " AND createdAt >= '2026-11-01T14:00:00.000Z' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)",
    );
  });

  it('is empty with no conditions', () => {
    expect(new Where().toString()).toBe('');
  });

  it('rejects bad input', () => {
    expect(() => where().eq('price = 1 OR 1', 1)).toThrow(TypeError);
    expect(() => where().in('id', [])).toThrow(TypeError);
    expect(() => where().gt('price', Number.NaN)).toThrow(TypeError);
    expect(() => literal(null as unknown as string)).toThrow(TypeError);
  });
});
