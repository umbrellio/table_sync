# frozen_string_literal: true

class TableSync::Publishing::Params::Single < TableSync::Publishing::Params::Base
  attr_reader :object, :routing_key, :headers
  
  def initialize(object)
    @object      = object
    @routing_key = calculated_routing_key
    @headers     = calculated_headers
  end

  private

  def object_class
    object.class.name
  end

  def attrs_for_routing_key
    object.try(:attrs_for_routing_key) || super
  end

  def attrs_for_headers
    object.try(:attrs_for_headers) || super
  end

  def exchange_name
    TableSync.exchange_name
  end
end
