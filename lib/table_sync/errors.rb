# frozen_string_literal: true

module TableSync
  Error = Class.new(StandardError)

  class UpsertError < Error
    def initialize(data:, target_keys:, result:)
      super "data: #{data.inspect}, target_keys: #{target_keys.inspect}, result: #{result.inspect}"
    end
  end

  class DestroyError < Error
    def initialize(data:, target_keys:, result:)
      super "data: #{data.inspect}, target_keys: #{target_keys.inspect}, result: #{result.inspect}"
    end
  end

  class DataError < Error
    # @param target_keys [Array<Symbol,String>]
    # @param target_attributes [Hash<Symbol|String,Any>]
    def initialize(data, target_keys, description)
      super(<<~MSG.squish)
        #{description}
        target_keys: #{target_keys}
        data: #{data}
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

  class InterfaceError < Error
    def initialize(object, method_name, parameters, description)
      parameters = parameters.map do |parameter|
        type, name = parameter

        case type
        when :req
          name.to_s
        when :keyreq
          "#{name}:"
        when :block
          "&#{name}"
        end
      end

      signature = "#{method_name}(#{parameters.join(", ")})"

      super("#{object} has to implement method `#{signature}`\n#{description}")
    end
  end

  UndefinedEvent = Class.new(Error)
  ORMNotSupported = Class.new(Error)

  class WrongOptionValue < Error
    def initialize(model, option, value)
      super("TableSync config for #{model.inspect} can't contain #{value.inspect} as #{option}")
    end
  end
end
