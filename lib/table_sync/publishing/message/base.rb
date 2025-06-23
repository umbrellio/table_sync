# frozen_string_literal: true

module TableSync::Publishing::Message
  class Base
    attr_accessor :custom_version,
                  :object_class,
                  :original_attributes,
                  :event

    attr_reader :objects

    def initialize(params = {})
      @custom_version        = params[:custom_version]
      @object_class          = params[:object_class]
      @original_attributes   = params[:original_attributes]
      @event                 = params[:event]

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
        object_class:, original_attributes:, event:,
      ).construct_list
    end

    # MESSAGE PARAMS

    def message_params
      params.merge(data:)
    end

    def data
      TableSync::Publishing::Data::Objects.new(
        objects:,
        event:,
        custom_version:,
      ).construct
    end

    # :nocov:
    def params
      raise NotImplementedError
    end
    # :nocov:

    # NOTIFY

    def notify!
      TableSync::Instrument.notify(
        table: model_naming.table,
        schema: model_naming.schema,
        event:,
        direction: :publish,
        count: objects.count,
      )
    end

    def model_naming
      TableSync.publishing_adapter.model_naming(objects.first.object_class)
    end
  end
end
