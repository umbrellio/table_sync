# frozen_string_literal: true

class TableSync::Publishing::Message::Batch < TableSync::Publishing::Message::Base
  attribute :headers
  attribute :routing_key

  private

  def data
    TableSync::Publishing::Data::Batch.new(
      objects: objects, state: state
    ).construct
  end

  def params
    TableSync::Publishing::Params::Batch.new(
      klass: klass, headers: headers, routing_key: routing_key
    ).construct
  end
end
