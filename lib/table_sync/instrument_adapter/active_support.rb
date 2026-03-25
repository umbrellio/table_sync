# frozen_string_literal: true

module TableSync::InstrumentAdapter
  module ActiveSupport
    module_function

    def notify( # rubocop:disable Metrics/ParameterLists
      table:,
      schema:,
      event:,
      direction:,
      count: 1,
      compress: false
    )
      ::ActiveSupport::Notifications.instrument "tablesync.#{direction}.#{event}",
                                                count:,
                                                table: table.to_s,
                                                schema: schema.to_s,
                                                event:,
                                                direction:,
                                                compress:
    end
  end
end
