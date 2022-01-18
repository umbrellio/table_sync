# frozen_string_literal: true

module TableSync::Publishing::Message
  class Raw
    include Tainbox

    attribute :object_class
    attribute :model_name
    attribute :original_attributes
    attribute :routing_key
    attribute :headers

    attribute :event

    def publish
      Rabbit.publish(message_params)

      notify!
    end

    # NOTIFY

    def notify!
      TableSync::Instrument.notify(
        table: model_naming.table,
        schema: model_naming.schema,
        event: event,
        count: original_attributes.count,
        direction: :publish,
      )
    end

    def model_naming
      TableSync.publishing_adapter.model_naming(object_class.constantize)
    end

    # MESSAGE PARAMS

    def message_params
      params.merge(data: data)
    end

    def data
      TableSync::Publishing::Data::Raw.new(
        model_name: resolve_model_name, attributes_for_sync: original_attributes, event: event,
      ).construct
    end

    def resolve_model_name
      model_name || object_class
    end

    def params
      TableSync::Publishing::Params::Raw.new(
        attributes.slice(:object_class, :headers, :routing_key).compact,
      ).construct
    end
  end
end
