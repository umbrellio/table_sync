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

    def attrs_for_routing_key
      if object.respond_to?(:attrs_for_routing_key)
        object.attrs_for_routing_key
      else
        object.attributes
      end
    end

    def attrs_for_headers
      if object.respond_to?(:attrs_for_headers)
        object.attrs_for_headers
      else
        object.attributes
      end
    end

    def exchange_name
      TableSync.exchange_name
    end
  end
end
