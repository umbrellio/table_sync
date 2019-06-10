# frozen_string_literal: true

module TableSync
  # rubocop:disable Style/MissingRespondToMissing, Style/MethodMissingSuper
  class ConfigDecorator
    include ::TableSync::EventActions

    def initialize(config, handler)
      @config = config
      @handler = handler
    end

    def method_missing(name, *args)
      value = @config.send(name)

      if value.is_a?(Proc)
        value.call(
          event: @handler.event,
          model: @handler.model,
          version: @handler.version,
          project_id: @handler.project_id,
          data: @handler.data,
          current_row: args.first,
        )
      else
        value
      end
    end

    def allow_event?(event)
      @config.allow_event?(event)
    end
  end
  # rubocop:enable Style/MissingRespondToMissing, Style/MethodMissingSuper
end
