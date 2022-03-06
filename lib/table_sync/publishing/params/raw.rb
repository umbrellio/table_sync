# frozen_string_literal: true

module TableSync::Publishing::Params
  class Raw < Base
    include Tainbox

    attribute :model_name

    attribute :exchange_name, default: -> { TableSync.exchange_name }
    attribute :routing_key,   default: -> { calculated_routing_key }
    attribute :headers,       default: -> { calculated_headers }

    private

    alias_method :object_class, :model_name

    def attributes_for_routing_key
      {}
    end

    def attributes_for_headers
      {}
    end
  end
end
