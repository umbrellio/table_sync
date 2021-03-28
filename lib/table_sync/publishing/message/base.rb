# frozen_string_literal: true

module TableSync::Publishing::Message
  class Base
    include Tainbox
    
    NO_OBJECTS_FOR_SYNC = Class.new(StandardError)

    attr_reader :objects

    attribute :object_class
    attribute :original_attributes
    attribute :event

    def initialize(params)
      super(params)

      @objects = find_or_init_objects

      raise NO_OBJECTS_FOR_SYNC if objects.empty?
    end

    def publish
      Rabbit.publish(message_params)

      notify!
    end

    def notify!
      # model_naming = TableSync.publishing_adapter.model_naming(object_class)
      # TableSync::Instrument.notify table: model_naming.table, schema: model_naming.schema,
      #                              event: event, direction: :publish
    end

    private

    def find_or_init_objects
      TableSync::Publishing::Helpers::Objects.new(
        object_class: object_class, original_attributes: original_attributes, event: event,
      ).construct_list
    end

    def data
      TableSync::Publishing::Data::Objects.new(
        objects: objects, event: event
      ).construct
    end

    # MESSAGE PARAMS

    def message_params
      params.merge(data: data)
    end

    def data
      TableSync::Publishing::Data::Objects.new(
        objects: objects, event: event
      ).construct
    end

    def params
      raise NotImplementedError
    end
  end
end