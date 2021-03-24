# frozen_string_literal: true

class TableSync::Publishing::Message::Raw
  include Tainbox

  attribute :object_class
  attribute :original_attributes
  attribute :routing_key
  attribute :headers

  attribute :event

  def publish
    Rabbit.publish(message_params)
  end

  private

  def message_params
    params.merge(data: data)
  end

  def data
    TableSync::Publishing::Data::Raw.new(
      attributes_for_sync: original_attributes, event: event,
    ).construct
  end

  def params
    TableSync::Publishing::Params::Raw.new(
      object_class: object_class, routing_key: routing_key, headers: headers,
    ).construct
  end
end
