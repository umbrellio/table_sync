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

  class DestroyError < Error
    def initialize(data)
      super("Destroy has changed too many rows; data: #{data.inspect}")
    end
  end

  class EmptyAttributesError < Error
    def initialize(data)
      "Destroy event includes empty attributes; data: #{data.inspect}"
    end
  end

  class UnprovidedEventTargetKeysError < Error
    # @param target_keys [Array<Symbol,String>]
    # @param target_attributes [Hash<Symbol|String,Any>]
    def initialize(target_keys, target_attributes)
      super(<<~MSG.squish)
        Some target keys not found in received attributes!
        (Expects: #{target_keys}, Actual: #{target_attributes})
      MSG
    end
  end

  # @api public
  # @since 2.2.0
  PluginError = Class.new(Error)

  # @api public
  # @since 2.2.0
  class UnregisteredPluginError < PluginError
    # @param plugin_name [Any]
    def initialize(plugin_name)
      super("#{plugin_name} plugin is not registered")
    end
  end

  # @api public
  # @since 2.2.0
  class AlreadyRegisteredPluginError < PluginError
    # @param plugin_name [Any]
    def initialize(plugin_name)
      super("#{plugin_name} plugin already exists")
    end
  end
end
