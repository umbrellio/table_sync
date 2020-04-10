# frozen_string_literal: true

# @api public
# @since 2.3.0
module TableSync::Plugins
  require_relative "plugins/registry"
  require_relative "plugins/access_mixin"
  require_relative "plugins/abstract"

  # @since 2.3.0
  @plugin_registry = Registry.new
  # @since 2.3.0
  @access_lock = Mutex.new

  class << self
    # @param plugin_name [Symbol, String]
    # @return [void]
    #
    # @api public
    # @since 2.3.0
    def load(plugin_name)
      thread_safe { plugin_registry[plugin_name].load! }
    end

    # @return [Array<String>]
    #
    # @api public
    # @since 2.3.0
    def loaded_plugins
      thread_safe do
        # rubocop:disable Style/MultilineBlockChain
        plugin_registry.select do |_plugin_name, plugin_module|
          plugin_module.loaded?
        end.map do |plugin_name, _plugin_module|
          plugin_name
        end
        # rubocop:enable Style/MultilineBlockChain
      end
    end

    # @return [Array<String>]
    #
    # @api public
    # @since 2.3.0
    def names
      thread_safe { plugin_registry.names }
    end

    # @param plugin_name [Symbol, String]
    # @return [void]
    #
    # @api private
    # @since 2.3.0
    def register_plugin(plugin_name, plugin_module)
      thread_safe { plugin_registry[plugin_name] = plugin_module }
    end

    private

    # @return [TableSync::Plugins::Registry]
    #
    # @api private
    # @since 2.3.0
    attr_reader :plugin_registry

    # @return [Mutex]
    #
    # @api private
    # @since 2.3.0
    attr_reader :access_lock

    # @return [void]
    #
    # @api private
    # @since 2.3.0
    def thread_safe
      access_lock.synchronize { yield if block_given? }
    end
  end
end
