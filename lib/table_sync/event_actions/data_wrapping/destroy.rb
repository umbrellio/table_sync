# frozen_string_literal: true

# froezn_string_literal: true

class TableSync::EventActions::DataWrapping::Destroy < TableSync::EventActions::DataWrapping::Base
  def type
    :destroy
  end

  def each(&block)
    [event_data].each(&block)
  end

  def destroy?
    true
  end

  def update?
    false
  end
end
