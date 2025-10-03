# frozen_string_literal: true

class TableSync::Utils::Schema
  class Validator
    class Type
      class Decimal < Type
        def valid?(value)
          !Float(value, exception: false).nil?
        end
      end

      class DateTime < Type
        def valid?(value)
          Date._parse(value.to_s).any?
        end
      end

      class Boolean < Type
        def valid?(value)
          %w[true false t f 0 1 on off].include?(value.to_s.downcase)
        end
      end

      class Text < Type
        def valid?(value)
          return true if value.is_a?(::String)
          return true if value.is_a?(::Symbol)
          return true if Type::DECIMAL.valid?(value)
          return true if Type::BOOLEAN.valid?(value)
          return true if Type::DATETIME.valid?(value)
          false
        end
      end

      attr_reader :display_name

      def initialize(display_name)
        @display_name = display_name
      end

      # @!method valid?

      # rubocop:disable Layout/ClassStructure
      DECIMAL = Decimal.new("Decimal")
      DATETIME = DateTime.new("DateTime")
      BOOLEAN = Boolean.new("Boolean")
      STRING = Text.new("String")
      # rubocop:enable Layout/ClassStructure

      def validate(value)
        return if value.nil?
        return if valid?(value)
        "expected #{display_name}, got: #{value.class}"
      end

      def inspect
        display_name.inspect
      end
    end
  end
end
