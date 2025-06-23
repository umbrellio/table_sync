# frozen_string_literal: true

module TableSync::Publishing::Params
  class Batch < Base
    attr_accessor :object_class
    attr_writer :exchange_name, :routing_key, :headers

    def initialize(attrs = {})
      self.object_class   = attrs[:object_class]
      @exchange_name      = attrs[:exchange_name]
      @routing_key        = attrs[:routing_key]
      @headers            = attrs[:headers]
    end

    def exchange_name
      @exchange_name || TableSync.exchange_name
    end

    def routing_key
      @routing_key || calculated_routing_key
    end

    def headers
      @headers || calculated_headers
    end

    private

    def attributes_for_routing_key
      {}
    end

    def attributes_for_headers
      {}
    end
  end
end
