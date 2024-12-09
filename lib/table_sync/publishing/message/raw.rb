# frozen_string_literal: true

module TableSync::Publishing::Message
  class Raw
    include Tainbox

    attribute :model_name
    attribute :table_name
    attribute :schema_name
    attribute :original_attributes

    attribute :routing_key
    attribute :headers
    attribute :custom_version
    attribute :event

    def publish
      Rabbit.publish(message_params)

      notify!
    end

    # NOTIFY

    def notify!
      TableSync::Instrument.notify(
        table: table_name,
        schema: schema_name,
        event:,
        count: original_attributes.count,
        direction: :publish,
      )
    end

    # MESSAGE PARAMS

    def message_params
      params.merge(data:)
    end

    def data
      TableSync::Publishing::Data::Raw.new(
        model_name:,
        attributes_for_sync: original_attributes,
        event:,
        custom_version:,
      ).construct
    end

    def params
      TableSync::Publishing::Params::Raw.new(
        attributes.slice(:model_name, :headers, :routing_key).compact,
      ).construct
    end
  end
end
