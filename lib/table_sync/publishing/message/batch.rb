# frozen_string_literal: true

module TableSync::Publishing::Message
  class Batch < Base
    attribute :headers
    attribute :routing_key

    def params
      TableSync::Publishing::Params::Batch.new(**params_keys).construct
    end

    def params_keys
      { object_class: object_class }.tap do |hash|
        hash[:headers] = headers unless headers.nil?
        hash[:routing_key] = routing_key unless routing_key.nil?
      end
    end
  end
end
