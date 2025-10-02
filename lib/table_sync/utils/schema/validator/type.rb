# frozen_string_literal: true

class TableSync::Utils::Schema
  class Validator
    class Type
      attr_reader :display_name
      attr_reader :klasses

      def initialize(display_name, klasses)
        @display_name = display_name
        @klasses = klasses
      end

      def validate(value)
        return if value.nil?
        return if klasses.any? { |klass| value.is_a?(klass) }
        "expected #{display_name}, got: #{value.class}"
      end

      def inspect
        display_name.inspect
      end

      STRING = new("String", [String]).freeze
      DATETIME = new("DateTime", [::Sequel::SQLTime, Date, Time, DateTime]).freeze
      INTEGER = new("Integer", [Integer]).freeze
      DECIMAL = new("Decimal", [Numeric]).freeze
      BOOLEAN = new("Boolean", [TrueClass, FalseClass]).freeze
    end
  end
end
