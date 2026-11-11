# frozen_string_literal: true

module Noosh24
  module Model
    EMPTY = {}.freeze

    attr_reader :raw

    def initialize(raw: EMPTY, **fields)
      @raw = raw
      super(**fields)
    end
  end

  module Convert
    module_function

    def mapping(value)
      value.is_a?(Hash) ? value : Model::EMPTY
    end

    def str(value)
      case value
      when nil, Hash, Array then nil
      when String then value
      else value.to_s.freeze
      end
    end

    def int(value)
      case value
      when Integer then value
      when Float then value.finite? ? value.to_i : nil
      end
    end

    def float(value)
      case value
      when Integer, Float then value.to_f
      end
    end

    def bool(value)
      case value
      when nil, Hash, Array then nil
      when true, false then value
      when Numeric then !value.zero?
      when String then !value.empty?
      else true
      end
    end

    def time(value)
      return nil unless value.is_a?(String) && !value.empty?

      Time.iso8601(value.strip).utc.freeze
    rescue ArgumentError
      nil
    end

    def strings(value)
      return [].freeze unless value.is_a?(Array)

      value.filter_map { |item| str(item) }.freeze
    end

    def floats(value)
      return {}.freeze unless value.is_a?(Hash)

      value.each_with_object({}) do |(key, item), out|
        out[key.to_s.freeze] = item.to_f if item.is_a?(Integer) || item.is_a?(Float)
      end.freeze
    end

    def date_param(value)
      value.is_a?(Date) || value.is_a?(Time) ? value.strftime("%Y-%m-%d") : value.to_s
    end

    def object(value, model)
      value.is_a?(Hash) ? model.from_hash(value) : nil
    end

    def list_of(value, model)
      return [].freeze unless value.is_a?(Array)

      value.filter_map { |item| model.from_hash(item) if item.is_a?(Hash) }.freeze
    end

    def map_of(value, model)
      return {}.freeze unless value.is_a?(Hash)

      value.each_with_object({}) do |(key, item), out|
        out[key.to_s.freeze] = model.from_hash(item) if item.is_a?(Hash)
      end.freeze
    end
  end
end
