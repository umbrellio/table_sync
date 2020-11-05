# frozen_string_literal: true

class TableSync::Publishing::MessageID
  def initialize
    Thread.current[:ts_message_id] ||= 0
  end

  def generate
    "#{pid}-#{thread_id}-#{current_numerical_id + 1}"
  end

  def inc_numerical_id!
    Thread.current[:ts_message_id] += 1
  end

  private

  def pid
    Process.pid
  end

  def thread_id
    Thread.current.object_id
  end

  def current_numerical_id
    Thread.current[:ts_message_id]
  end
end
