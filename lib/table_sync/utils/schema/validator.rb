# frozen_string_literal: true

require_relative "validator/type"

class TableSync::Utils::Schema
  class Validator
    attr_reader :type

    def initialize(type)
      @type = type
    end

    def validate(value)
      type.validate(value)
    end

    def inspect
      type.inspect
    end
  end
end
