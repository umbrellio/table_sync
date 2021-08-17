# frozen_string_literal: true

class TableSync::Publishing::Raw
  include Tainbox

  attribute :object_class
  attribute :original_attributes

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

# event

# debounce
# serialization
# def jobs
# enqueue

# publishers

# specs

# docs

# cases

# changes

# add validations?
