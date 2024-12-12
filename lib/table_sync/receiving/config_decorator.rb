# frozen_string_literal: true

module TableSync::Receiving
  class ConfigDecorator
    extend Forwardable

    def_delegators :@config, :allow_event?
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

    def method_missing(name, **additional_params, &)
      value = @config.send(name)
      value.is_a?(Proc) ? value.call(@default_params.merge(additional_params), &) : value
    end
  end
end
