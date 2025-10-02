# frozen_string_literal: true

# Next code checks that hash values have required data types

require_relative "schema/builder"

class TableSync::Utils::Schema
  attr_reader :schema

  def initialize(schema)
    @schema = schema
  end

  def validate(data)
    errors = nil
    data.each do |row|
      schema.each do |key, value|
        if (error = value.validate(row[key]))
          errors ||= {}
          errors[key] = error
        end
      end

      return errors.freeze unless errors.nil?
    end
    errors
  end
end
