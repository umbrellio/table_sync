# frozen_string_literal: true

class TableSync::Publishing::Publisher
  include Tainbox

  attribute :klass
  attribute :attrs
  attribute :state

  attribute :debounce_time, default: 60

  def publish
    message.publish
  end

  private

  def message
    TableSync::Publishing::Message::Object.new(
      klass: klass, attrs: attrs, state: state
    )
  end

  # debounces, queues
end
