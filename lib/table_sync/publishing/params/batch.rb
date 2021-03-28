# frozen_string_literal: true

module TableSync::Publishing::Params
	class Batch < Base
	  include Tainbox

	  attribute :object_class

	  attribute :exchange_name, default: -> { TableSync.exchange_name }
	  attribute :routing_key,   default: -> { calculated_routing_key }
	  attribute :headers,       default: -> { calculated_headers }
	end
end
