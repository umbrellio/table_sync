# frozen_string_literal: true

module TableSync::Instrument
  module_function

  def notify(*args)
    notifier&.notify(*args)
  end

  def subscribe(*args)
    notifier&.subscribe(*args)
  end

  def unsubscribe(*args)
    notifier&.unsubscribe(*args)
  end

  def notifier
    TableSync.notifier
  end
end

module TableSync::Instrument::DSL
  def subscribe(name, &block)
    TableSync.notifier.subscribe(name, &block)
  end

  def unsubscribe(subscriber)
    TableSync.notifier.unsubscribe(subscriber)
  end
end
