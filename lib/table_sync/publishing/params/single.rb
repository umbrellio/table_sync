# frozen_string_literal: true

module TableSync::Publishing::Params
  class Single < Base
    attr_reader :object, :routing_key, :headers

    def initialize(object:)
      @object      = object
      @routing_key = calculated_routing_key
      @headers     = calculated_headers
    end

    private

    def object_class
      object.object_class.name
    end

    def attributes_for_routing_key
      object.attributes_for_routing_key
    end

    def attributes_for_headers
      object.attributes_for_headers
    end

    def exchange_name
      TableSync.exchange_name
    end
  end
end
