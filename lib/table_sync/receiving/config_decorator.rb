# frozen_string_literal: true

module TableSync::Receiving
  class ConfigDecorator
    # rubocop:disable Metrics/ParameterLists
    def initialize(config:, event:, model:, version:, project_id:, raw_data:)
      @config = config

      @default_params = {
        event:,
        model:,
        version:,
        project_id:,
        raw_data:,
      }
    end
    # rubocop:enable Metrics/ParameterLists

    def option(name, **additional_params, &)
      value = @config.option(name)
      value.is_a?(Proc) ? value.call(@default_params.merge(additional_params), &) : value
    end

    def model
      @config.model
    end

    def allow_event?(name)
      @config.allow_event?(name)
    end
  end
end
