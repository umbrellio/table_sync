# frozen_string_literal: true

class TableSync::Publishing::Params::Batch < TableSync::Publishing::Params::Base
  include Tainbox

  attribute :object_class

  attribute :exchange_name, default: -> { TableSync.exchange_name }
  attribute :routing_key,   default: -> { calculated_routing_key }
  attribute :headers,       default: -> { calculated_headers }
end
