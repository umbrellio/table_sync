# frozen_string_literal: true

module TableSync::Publishing::Data
  class Raw
    attr_reader :model_name, :attributes_for_sync, :event

    def initialize(model_name:, attributes_for_sync:, event:)
      @model_name = model_name
      @attributes_for_sync = attributes_for_sync
      @event = TableSync::Event.new(event)
    end

    def construct
      {
        model: model_name,
        attributes: wrapped_attributes_for_sync,
        version: version,
        event: event.resolve,
        metadata: event.metadata,
      }
    end

    def wrapped_attributes_for_sync
      attributes_for_sync.is_a?(Array) ? attributes_for_sync : [attributes_for_sync]
    end

    def version
      Time.current.to_f
    end
  end
end
