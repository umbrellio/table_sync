# frozen_string_literal: true

module TableSync::Receiving
  module DSL
    def configs
      @configs ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def receive(source, to_table: nil, to_model: nil, events: [:update, :destroy], &block)
      model = to_table ? TableSync.receiving_model.new(to_table) : to_model

      TableSync::Utils::InterfaceChecker.new(model).implements(:receiving_model)

      config = ::TableSync::Receiving::Config.new(model: model, events: events)

      config.instance_exec(&block) if block

      configs[source.to_s] << config

      self
    end
  end
end
