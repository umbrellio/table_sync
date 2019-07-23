# frozen_string_literal: true

module TableSync::Instrument
  module_function

  def notify(*args)
    TableSync.notifier&.notify(*args)
  end
end
