# frozen_string_literal: true

class TableSync::Publishing::Params::Object
  attribute :object

  private

  def klass
    object.class.name
  end

  # ROUTING KEY

  def routing_key
    calculated_routing_key
  end

  def attrs_for_routing_key
    object.try(:attrs_for_routing_key) || super
  end

  # HEADERS

  def headers
    calculated_headers
  end

  def attrs_for_headers
    object.try(:attrs_for_headers) || super
  end
end
