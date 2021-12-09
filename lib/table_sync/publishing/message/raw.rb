# frozen_string_literal: true

module TableSync::Publishing::Message
  class Raw
    include Tainbox

    attribute :object_class
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
        object_class: object_class, attributes_for_sync: original_attributes, event: event,
      ).construct
    end

    def params
      TableSync::Publishing::Params::Raw.new(**params_keys).construct
    end

    def params_keys
      { object_class: object_class }.tap do |hash|
        hash[:headers] = headers unless headers.nil?
        hash[:routing_key] = routing_key unless routing_key.nil?
      end
    end
  end
end
