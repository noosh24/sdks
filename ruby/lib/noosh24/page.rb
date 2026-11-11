# frozen_string_literal: true

module Noosh24
  class Page
    include Enumerable

    attr_reader :items, :total, :limit, :offset

    def initialize(items:, total:, limit:, offset:)
      @items = items.freeze
      @total = total
      @limit = limit
      @offset = offset
      freeze
    end

    def has_more?
      !items.empty? && offset + items.size < total
    end

    def next_offset
      offset + items.size
    end

    def each(&)
      return enum_for(:each) { items.size } unless block_given?

      items.each(&)
      self
    end

    def size
      items.size
    end
    alias length size

    def empty?
      items.empty?
    end

    def ==(other)
      other.is_a?(Page) && [other.items, other.total, other.limit, other.offset] == [items, total, limit, offset]
    end
    alias eql? ==

    def hash
      [self.class, items, total, limit, offset].hash
    end

    def inspect
      "#<#{self.class.name} items=#{items.size} total=#{total} limit=#{limit} offset=#{offset}>"
    end
  end

  CreateReservationResult = Data.define(:reservation, :created) do
    alias_method :created?, :created
  end
end
