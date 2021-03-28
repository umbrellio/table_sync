# frozen_string_literal: true

module TableSync::Publishing::Helpers
  class Attributes
    BASE_SAFE_JSON_TYPES = [
    	NilClass,
    	String,
    	TrueClass,
    	FalseClass,
    	Numeric,
    	Symbol,
    ].freeze

    NOT_MAPPED = Object.new

    attr_reader :attributes

    def initialize(attributes)
      @attributes = attributes.deep_symbolize_keys
    end

    def serialize
    	filter_safe_for_serialization(attributes)
    end

    def filter_safe_for_serialization(object)
      case object
      when Array
        object.each_with_object([]) do |value, memo|
          value = filter_safe_for_serialization(value)
          memo << value if object_mapped?(value)
        end
      when Hash
        object.each_with_object({}) do |(key, value), memo|
          key = filter_safe_for_serialization(key)
          value = filter_safe_hash_values(value)
          memo[key] = value if object_mapped?(key) && object_mapped?(value)
        end
      when Float::INFINITY
        NOT_MAPPED
      when *BASE_SAFE_JSON_TYPES
        object
      else # rubocop:disable Lint/DuplicateBranch
        NOT_MAPPED
      end
    end

    def filter_safe_hash_values(value)
      case value
      when Symbol
        value.to_s
      else
        filter_safe_for_serialization(value)
      end
    end

    def object_mapped?(object)
      object != NOT_MAPPED
    end
  end
end