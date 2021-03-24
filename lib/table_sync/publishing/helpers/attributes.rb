# frozen_string_literal: true

class TableSync::Publishing::Helpers::Attributes
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes.deep_symbolize_keys
  end

  def serialize
  	attributes
  end
end
