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
            TableSync::Utils::Schema::Validator.new(type(value))
          end.compact
        end

        def type(value)
          case value[:type]
          when :string
            Type.new(String)
          when :datetime
            Type.new(Time)
          when :integer
            Type.new(Integer)
          when :decimal
            Type.new(Numeric)
          when /array/
            Type.new(Array)
          else
            Type.new(BasicObject)
          end
        end
      end
    end
  end
end
