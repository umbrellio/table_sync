# frozen_string_literal: true

class TableSync::Publishing::Params::Batch
  attribute :klass

  attribute :routing_key, default: -> { calculated_routing_key }
  attribute :headers,     default: -> { calculated_headers }

  private

  def attrs_for_routing_key
    {}
  end

  def attrs_for_headers
    {}
  end
end