# frozen_string_literal: true

module TableSync::Publishing::Data
  class Raw
    attr_reader :model_name, :attributes_for_sync, :event, :custom_version

    def initialize(model_name:, attributes_for_sync:, event:, custom_version:)
      @model_name = model_name
      @attributes_for_sync = attributes_for_sync
      @event = TableSync::Event.new(event)
      @custom_version = custom_version
    end

    def construct
      {
        model: model_name,
        attributes: wrapped_attributes_for_sync,
        version: custom_version || version,
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
