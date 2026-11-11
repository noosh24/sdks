# frozen_string_literal: true

module Noosh24
  class Where
    FIELD = /\A[A-Za-z][A-Za-z0-9_.]*\z/

    def self.literal(value)
      case value
      when true then "true"
      when false then "false"
      when Integer then value.to_s
      when Float then number(value)
      when String then "'#{value.gsub("'", "''")}'"
      when Time then "'#{timestamp(value)}'"
      when DateTime then "'#{timestamp(value.to_time)}'"
      when Date then "'#{value.iso8601}'"
      when nil then raise ArgumentError, "where does not take nil"
      else raise ArgumentError, "where takes strings, numbers, booleans, dates and times, not #{value.class}"
      end
    end

    def self.number(value)
      raise ArgumentError, "Numbers in where must be finite" unless value.finite?

      value == value.to_i ? value.to_i.to_s : value.to_s
    end

    def self.timestamp(time)
      return time.iso8601 if time.nsec.zero?

      time.iso8601((time.nsec % 1000).zero? ? 6 : 9)
    end

    private_class_method :number, :timestamp

    def initialize
      @conditions = []
    end

    def eq(field, value) = add(field, "=", value)

    def ne(field, value) = add(field, "!=", value)

    def gt(field, value) = add(field, ">", value)

    def gte(field, value) = add(field, ">=", value)

    def lt(field, value) = add(field, "<", value)

    def lte(field, value) = add(field, "<=", value)

    def in(field, values)
      items = Array(values)
      raise ArgumentError, "in needs at least one value" if items.empty?

      @conditions << "#{check(field)} in (#{items.map { |item| self.class.literal(item) }.join(', ')})"
      self
    end

    def empty?
      @conditions.empty?
    end

    def to_s
      @conditions.join(" AND ")
    end

    def inspect
      "#<#{self.class.name} #{to_s.inspect}>"
    end

    private

    def add(field, operator, value)
      @conditions << "#{check(field)} #{operator} #{self.class.literal(value)}"
      self
    end

    def check(field)
      raise ArgumentError, "#{field.inspect} is not a field name" unless field.is_a?(String) && FIELD.match?(field)

      field
    end
  end

  def self.where
    Where.new
  end
end
