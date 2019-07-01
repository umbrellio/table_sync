# frozen_string_literal: true

module TableSync::Instrument
  extend self

  def update(table, &block)
    instrument(table, "receive.update", &block)
  end

  def destroy(table, &block)
    instrument(table, "receive.destroy", &block)
  end

  def instrument(table, event)
    data = yield
    ActiveSupport::Notifications.instrument "tablesync.#{event}",
                                            count: data.count,
                                            table: table,
                                            event: event
    data
  end

  def subscribe(name, &block)
    ActiveSupport::Notifications.subscribe(name, &block)
  end
end
