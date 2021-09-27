# frozen_string_literal: true

module TableSync::Publishing::Data
  class Raw
    attr_reader :object_class, :attributes_for_sync, :event

    def initialize(object_class:, attributes_for_sync:, event:)
      @object_class = object_class
      @attributes_for_sync = attributes_for_sync
      @event = TableSync::Event.new(event)
    end

    def construct
      {
        model: object_class,
        attributes: attributes_for_sync,
        version: version,
        event: event.resolve,
        metadata: event.metadata,
      }
    end

    def version
      Time.current.to_f
    end
  end
end
