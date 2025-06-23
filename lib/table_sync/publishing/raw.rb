# frozen_string_literal: true

class TableSync::Publishing::Raw
  include TableSync::Utils::RequiredValidator

  attr_accessor :model_name,
                :table_name,
                :schema_name,
                :original_attributes,
                :custom_version,
                :routing_key,
                :headers,
                :event

  def initialize(attributes = {})
    attributes ||= {}

    @model_name           = attributes[:model_name]
    @table_name           = attributes[:table_name]
    @schema_name          = attributes[:schema_name]
    @original_attributes  = attributes[:original_attributes]
    @custom_version       = attributes[:custom_version]
    @routing_key          = attributes[:routing_key]
    @headers              = attributes[:headers]
    @event                = attributes.fetch(:event, :update)
  end

  require_attributes :model_name, :original_attributes

  def publish_now
    message.publish
  end

  def message
    TableSync::Publishing::Message::Raw.new(attributes)
  end

  private

  def attributes
    {
      model_name: model_name,
      table_name: table_name,
      schema_name: schema_name,
      original_attributes: original_attributes,
      custom_version: custom_version,
      routing_key: routing_key,
      headers: headers,
      event: event,
    }
  end
end
