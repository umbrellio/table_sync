# frozen_string_literal: true

module TableSync::InstrumentAdapter
  module ActiveSupport
    module_function

    def notify(table:, schema:, event:, direction:, count: 1)
      ::ActiveSupport::Notifications.instrument "tablesync.#{direction}.#{event}",
                                                count:,
                                                table: table.to_s,
                                                schema: schema.to_s,
                                                event:,
                                                direction:
    end
  end
end
