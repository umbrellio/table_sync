# frozen_string_literal: true

module TableSync::Instrument
  extend self

  def notify(table:, event:, direction:, count: 1)
    ActiveSupport::Notifications.instrument "tablesync.#{direction}.#{event}",
                                            count: count,
                                            table: table.to_s,
                                            event: event,
                                            direction: direction
  end

  def subscribe(name, &block)
    ActiveSupport::Notifications.subscribe(name, &block)
  end
end
