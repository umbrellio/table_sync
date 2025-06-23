# frozen_string_literal: true

module TableSync::Publishing::Message
  class Batch < Base
    attr_accessor :headers, :routing_key

    def initialize(params = {})
      super

      @headers     = params[:headers]
      @routing_key = params[:routing_key]
    end

    def params
      TableSync::Publishing::Params::Batch.new(
        { object_class:, headers:, routing_key: }.compact,
      ).construct
    end
  end
end
