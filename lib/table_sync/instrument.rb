# frozen_string_literal: true

module TableSync::Instrument
  module Receive
    extend self

    def notify(table:, event:)
      data = yield
      ActiveSupport::Notifications.instrument "tablesync.receive.#{event}",
                                              count: data.count,
                                              table: table.to_s,
                                              event: event,
                                              direction: :receive
      data
    end

    def update(table, &block)
      notify(table: table, event: :update, &block)
    end

    def destroy(table, &block)
      notify(table: table, event: :destroy, &block)
    end
  end

  module Publish
    extend self

    def notify(table:, event:, count: 1)
      ActiveSupport::Notifications.instrument "tablesync.publish.#{event}",
                                              count: count,
                                              table: table.to_s,
                                              event: event,
                                              direction: :publish
    end
  end

  extend self

  def subscribe(name, &block)
    ActiveSupport::Notifications.subscribe(name, &block)
  end
end
