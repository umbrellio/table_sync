# frozen_string_literal: true

class TableSync::Utils::Schema
  module Builder
    class Sequel
      class << self
        Type = TableSync::Utils::Schema::Validator::Type

        def build(model)
          TableSync::Utils::Schema.new(schema(model))
        end

        private

        def schema(model)
          model.db_schema.transform_values do |value|
            next unless (type = type(value))
            TableSync::Utils::Schema::Validator.new(type)
          end.tap(&:compact!)
        end

        def type(value)
          case value[:type]
          when :string
            Type::STRING
          when :datetime, :date, :time
            Type::DATETIME
          when :integer, :decimal, :float
            Type::DECIMAL
          when :boolean
            Type::BOOLEAN
          end
        end
      end
    end
  end
end
