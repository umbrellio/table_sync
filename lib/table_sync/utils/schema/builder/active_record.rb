# frozen_string_literal: true

class TableSync::Utils::Schema
  module Builder
    class ActiveRecord
      class << self
        Type = TableSync::Utils::Schema::Validator::Type

        def build(model)
          TableSync::Utils::Schema.new(schema(model))
        end

        private

        def schema(model)
          model.attribute_types.to_h do |key, value|
            next [nil, nil] unless (type = type(value))
            [key.to_sym, TableSync::Utils::Schema::Validator.new(type)]
          end.tap(&:compact!)
        end

        def type(value)
          case value
          when ActiveModel::Type::String,
               ActiveModel::Type::ImmutableString
            Type::STRING
          when ActiveModel::Type::DateTime,
               ActiveModel::Type::Date,
               ActiveModel::Type::Time
            Type::DATETIME
          when ActiveModel::Type::Integer
            Type::INTEGER
          when ActiveModel::Type::Decimal,
               ActiveModel::Type::Float,
               ActiveModel::Type::BigInteger
            Type::DECIMAL
          when ActiveModel::Type::Boolean
            Type::BOOLEAN
          end
        end
      end
    end
  end
end
