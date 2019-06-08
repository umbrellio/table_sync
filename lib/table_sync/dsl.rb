# frozen_string_literal: true

module TableSync
  module DSL
    def inherited(klass)
      klass.instance_variable_set(:@configs, configs.deep_dup)
      super
    end

    def configs
      @configs ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def receive(source, to_table:, events: nil, &block)
      config = ::TableSync::Config.new(
        model: TableSync.orm.model.new(to_table),
        events: events,
      )

      config.instance_exec(&block) if block

      configs[source.to_s] << config
    end
  end
end
