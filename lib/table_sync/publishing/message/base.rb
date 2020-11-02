# frozen_string_literal: true

class TableSync::Publishing::Message::Base
  include Tainbox

  attr_reader :objects

  attribute :klass
  attribute :attrs
  attribute :state

  def initialize(**params)
    super(**params)

    @objects = find_objects

    raise "Synced objects not found!" if objects.empty?
  end

  def publish
    Rabbit.publish(message_params)
  end

  def notify
    # notify stuff
  end

  private

  # find if update|create and new if destruction?

  def find_objects
    TableSync::Publishing::Message::FindObjects.new(
      klass: klass, attrs: attrs
    ).list
  end

  # MESSAGE PARAMS

  def message_params
    params.merge(data: data)
  end

  def data
    raise NotImplementedError
  end

  def params
    raise NotImplementedError
  end
end
