# frozen_string_literal: true

class TableSync::EventActions::DataWrapping::Destroy < TableSync::EventActions::DataWrapping::Base
  def type
    :destroy
  end

  def each
    yield(event_data)
  end

  def destroy?
    true
  end

  def update?
    false
  end
end
