# frozen_string_literal: true

module TableSync::Publishing::Message
  class Batch < Base
    attribute :headers
    attribute :routing_key

    def params
      TableSync::Publishing::Params::Batch.new(
        object_class: object_class, headers: headers, routing_key: routing_key,
      ).construct
    end
  end
end
