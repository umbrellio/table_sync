# frozen_string_literal: true

module TableSync::Receiving::Hooks
  class Once
    attr_reader :conditions, :handler, :lookup_code

    def initialize(conditions:, handler:)
      @conditions = conditions
      @handler = handler
      init_lookup_code
    end

    def enabled?
      conditions[:columns].any?
    end

    def perform(config:, targets:)
      target_keys = config.option(:target_keys)
      model = config.model

      targets.each do |target|
        next unless conditions?(target)

        model.transaction(isolation: model.isolation_level(:repeatable)) do
          model.find_and_save(row: target, target_keys:) do |entry|
            next unless allow?(entry)

            entry.hooks ||= []
            entry.hooks << lookup_code
            model.after_commit { handler.call(entry:) }
          end
        end
      end
    end

    private

    def allow?(entry)
      Array(entry.hooks).exclude?(lookup_code)
    end

    def init_lookup_code
      @lookup_code = conditions[:columns].map do |column|
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
