# frozen_string_literal: true

class TableSync::EventActions::DataWrapper::Base
  include Enumerable

  attr_reader :event_data

  def initialize(event_data)
    @event_data = event_data
  end

  def type
    raise NoMethodError # NOTE: for clarity
  end

  def destroy?
    false
  end

  def update?
    false
  end
end
