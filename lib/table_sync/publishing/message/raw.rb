# frozen_string_literal: true

module TableSync::Publishing::Message
  class Raw
    attr_accessor :model_name,
                  :table_name,
                  :schema_name,
                  :original_attributes,
                  :routing_key,
                  :headers,
                  :custom_version,
                  :event

    def initialize(params = {})
      self.model_name          = params[:model_name]
      self.table_name          = params[:table_name]
      self.schema_name         = params[:schema_name]
      self.original_attributes = params[:original_attributes]
      self.routing_key         = params[:routing_key]
      self.headers             = params[:headers]
      self.custom_version      = params[:custom_version]
      self.event               = params[:event]
    end

    def publish
      Rabbit.publish(**message_params)

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
        { model_name:, headers:, routing_key: }.compact,
      ).construct
    end
  end
end
