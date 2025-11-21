# frozen_string_literal: true

module TableSync::Receiving::Hooks
  class Once
    attr_reader :conditions, :config

    def initialize(conditions:, config:)
      @conditions = conditions
      @config = config
    end

    def perform(targets:, &)
      target_keys = config.option(:target_keys)
      model = config.model

      targets.each do |target|
        next unless conditions?(target)

        model.transaction(isolation: model.isolation_level(:repeatable)) do
          model.find_and_update(row: target, target_keys:) do |entry|
            next unless allow?(entry)

            entry.hooks ||= []
            entry.hooks << hook_lookup_code
            model.after_commit { yield(entry:) }
          end
        end
      end
    end

    private

    def allow?(entry)
      Array(entry.hooks).exclude?(hook_lookup_code)
    end

    def hook_lookup_code
      @hook_lookup_code ||= conditions[:columns].map do |column|
        "#{column}-#{conditions[column]}"
      end.join(":")
    end

    def conditions?(row)
      conditions[:columns].all? do |column|
        row[column] == (conditions[column] || row[column])
      end
    end
  end
end
