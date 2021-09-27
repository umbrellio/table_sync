# frozen_string_literal: true

module TableSync::Publishing::Message
  class Base
    include Tainbox

    attr_reader :objects

    attribute :object_class
    attribute :original_attributes
    attribute :event

    def initialize(params)
      super(params)

      @objects = find_or_init_objects

      raise TableSync::NoObjectsForSyncError if objects.empty? && TableSync.raise_on_empty_message
    end

    def publish
      return if original_attributes.blank?

      Rabbit.publish(message_params)

      notify!
    end

    def empty?
      objects.empty?
    end

    def find_or_init_objects
      TableSync::Publishing::Helpers::Objects.new(
        object_class: object_class, original_attributes: original_attributes, event: event,
      ).construct_list
    end

    # MESSAGE PARAMS

    def message_params
      params.merge(data: data)
    end

    def data
      TableSync::Publishing::Data::Objects.new(
        objects: objects, event: event,
      ).construct
    end

    def params
      raise NotImplementedError
    end

    # NOTIFY

    def notify!
      TableSync::Instrument.notify(
        table: model_naming.table,
        schema: model_naming.schema,
        event: event,
        direction: :publish,
        count: objects.count,
      )
    end

    def model_naming
      TableSync.publishing_adapter.model_naming(objects.first.object_class)
    end
  end
end
