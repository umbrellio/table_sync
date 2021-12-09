# frozen_string_literal: true

module TableSync::Publishing::Message
  class Batch < Base
    attribute :headers
    attribute :routing_key

    def params
      TableSync::Publishing::Params::Batch.new(
        attributes.slice(:object_class, :headers, :routing_key).compact,
      ).construct
    end
  end
end
