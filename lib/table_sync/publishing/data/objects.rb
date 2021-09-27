# frozen_string_literal: true

module TableSync::Publishing::Data
  class Objects
    attr_reader :objects, :event

    def initialize(objects:, event:)
      @objects = objects
      @event   = TableSync::Event.new(event)
    end

    def construct
      {
        model: model,
        attributes: attributes_for_sync,
        version: version,
        event: event.resolve,
        metadata: event.metadata,
      }
    end

    private

    def model
      if object_class.respond_to?(:table_sync_model_name)
        object_class.table_sync_model_name
      else
        object_class.name
      end
    end

    def version
      Time.current.to_f
    end

    def object_class
      objects.first.object_class
    end

    def attributes_for_sync
      objects.map do |object|
        if event.destroy?
          object.attributes_for_destroy
        else
          object.attributes_for_update
        end
      end
    end
  end
end
