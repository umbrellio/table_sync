# frozen_string_literal: true

# Next code checks that hash values have required data types

require_relative "schema/builder"

class TableSync::Utils::Schema
  attr_reader :schema

  def initialize(schema)
    @schema = schema
  end

  def validate(data)
    {}.tap do |errors|
      data.each do |row|
        schema.each do |key, value|
          errors[key] = value.validate(row[key])
        end
      end
      errors.compact!
      errors.freeze
    end
  end
end
