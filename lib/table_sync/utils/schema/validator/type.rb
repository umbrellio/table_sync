# frozen_string_literal: true

class TableSync::Utils::Schema
  class Validator
    class Type
      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def validate(value)
        case value
        when nil, klass
          nil
        else
          "expected #{klass}, got: #{value.class}"
        end
      end
    end
  end
end
