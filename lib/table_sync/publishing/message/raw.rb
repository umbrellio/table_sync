# frozen_string_literal: true

class TableSync::Publishing::Message::Raw
  include Tainbox

  attribute :klass
  attribute :attrs
  attribute :state
  attribute :routing_key
  attribute :headers

  def publish
    Rabbit.publish(message_params)
  end

  private

  def message_params
    params.merge(data: data)
  end

  def data
    TableSync::Publishing::Data::Raw.new(
      attributes_for_sync: attrs, state: state
    ).construct
  end

  def params
    TableSync::Publishing::Params::Batch.new(
      klass: klass, routing_key: routing_key, headers: headers,
    ).construct
  end
end
