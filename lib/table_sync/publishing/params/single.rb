# frozen_string_literal: true

module TableSync::Publishing::Params
  class Single < Base
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
      return object.attrs_for_routing_key if object.respond_to?(:attrs_for_routing_key) 
      
      super
    end

    def attrs_for_headers
      return object.attrs_for_headers if object.respond_to?(:attrs_for_headers) 
      
      super
    end

    def exchange_name
      TableSync.exchange_name
    end
  end
end
