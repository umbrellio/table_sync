# frozen_string_literal: true

class TableSync::Publishing::Message::Batch < TableSync::Publishing::Message::Base
  attribute :headers
  attribute :routing_key

  private

  def params
    TableSync::Publishing::Params::Batch.new(
      object_class: object_class, headers: headers, routing_key: routing_key
    ).construct
  end
end
