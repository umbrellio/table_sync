# frozen_string_literal: true

class TableSync::Publishing::Helpers::DebounceTime
  attr_reader :time

  def initialize(time)
    @time = time
  end
end