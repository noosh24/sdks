# frozen_string_literal: true

require_relative "test_helper"

class TestWhere < Minitest::Test
  def test_builds_and_only_conditions
    text = Noosh24.where
                  .eq("category", "Salads")
                  .ne("station", "")
                  .gt("price", 4.75)
                  .lte("prepMinutes", 15)
                  .eq("vegetarian", false)
                  .gte("createdAt", Time.new(2026, 11, 1, 18, 0, 0, "+04:00"))
                  .lt("price", 20.0)
                  .in("id", ["7f0c", "O'Neil", 3])
                  .to_s

    assert_equal "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 " \
                 "AND vegetarian = false AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 " \
                 "AND id in ('7f0c', 'O''Neil', 3)", text
  end

  def test_dates_and_fractional_times
    text = Noosh24.where
                  .lt("visitedOn", Date.new(2026, 11, 2))
                  .gte("createdAt", Time.utc(2026, 11, 1, 14, 0, 0, 500_000))
                  .to_s

    assert_equal "visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00.500000Z'", text
  end

  def test_empty_is_empty_string
    assert_equal "", Noosh24::Where.new.to_s
    assert_empty Noosh24::Where.new
  end

  def test_rejects_bad_input
    assert_raises(ArgumentError) { Noosh24.where.eq("price = 1 OR 1", 1) }
    assert_raises(ArgumentError) { Noosh24.where.eq(:price, 1) }
    assert_raises(ArgumentError) { Noosh24.where.in("id", []) }
    assert_raises(ArgumentError) { Noosh24.where.gt("price", Float::NAN) }
    assert_raises(ArgumentError) { Noosh24.where.gt("price", Float::INFINITY) }
    assert_raises(ArgumentError) { Noosh24.where.eq("note", nil) }
    assert_raises(ArgumentError) { Noosh24::Where.literal(nil) }
    assert_raises(ArgumentError) { Noosh24::Where.literal(Object.new) }
  end
end
