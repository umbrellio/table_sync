# frozen_string_literal: true

class TableSync::Publishing::Raw
  include Tainbox

  attribute :model_name
  attribute :table_name
  attribute :schema_name
  attribute :original_attributes
  attribute :custom_version
  attribute :routing_key
  attribute :headers

  attribute :event, default: :update

  def publish_now
    message.publish
  end

  def message
    TableSync::Publishing::Message::Raw.new(attributes)
  end
end
