# frozen_string_literal: true

module TableSync
  Error = Class.new(StandardError)

  class UpsertError < Error
    def initialize(data:, target_keys:, version_key:, first_sync_time_key:, default_values:)
      super <<~MSG
        Upsert has changed more than 1 row;
          data: #{data.inspect}
          target_keys: #{target_keys.inspect}
          version_key: #{version_key.inspect}
          first_sync_time_key: #{first_sync_time_key.inspect}
          default_values: #{default_values.inspect}
      MSG
    end
  end

  class UndefinedConfig < Error
    def initialize(model)
      super("Config not defined for model; model: #{model.inspect}")
    end
  end

  DestroyError = Class.new(Error)

  class InconsistentDestroyError < DestroyError
    def initialize(data)
      super("Destroy has changed more than 1 row; data: #{data.inspect}")
    end
  end

  UnprovidedDestroyTargetKeysError = Class.new(DestroyError)
end
