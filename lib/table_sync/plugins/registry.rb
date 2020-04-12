# frozen_string_literal: true

# @api private
# @since 2.2.0
class TableSync::Plugins::Registry
  include Enumerable

  # @return [void]
  #
  # @api private
  # @since 2.2.0
  def initialize
    @plugin_set = {}
    @access_lock = Mutex.new
  end

  # @param plugin_name [Symbol, String]
  # @return [TableSync::Plugins::Abstract]
  #
  # @api private
  # @since 2.2.0
  def [](plugin_name)
    thread_safe { fetch(plugin_name) }
  end

  # @param plugin_name [Symbol, String]
  # @param plugin_module [TableSync::Plugins::Abstract]
  # @return [void]
  #
  # @api private
  # @since 2.2.0
  def register(plugin_name, plugin_module)
    thread_safe { apply(plugin_name, plugin_module) }
  end
  alias_method :[]=, :register

  # @return [Array<String>]
  #
  # @api private
  # @since 2.2.0
  def names
    thread_safe { plugin_names }
  end

  # @param block [Block]
  # @return [Enumerable]
  #
  # @api private
  # @since 2.2.0
  def each(&block)
    thread_safe { iterate(&block) }
  end

  private

  # @return [Hash]
  #
  # @api private
  # @since 2.2.0
  attr_reader :plugin_set

  # @return [Mutex]
  #
  # @api private
  # @since 2.2.0
  attr_reader :access_lock

  # @return [void]
  #
  # @api private
  # @since 2.2.0
  def thread_safe
    access_lock.synchronize { yield if block_given? }
  end

  # @return [Array<String>]
  #
  # @api private
  # @since 2.2.0
  def plugin_names
    plugin_set.keys
  end

  # @param block [Block]
  # @return [Enumerable]
  #
  # @api private
  # @since 2.2.0
  def iterate(&block)
    block_given? ? plugin_set.each_pair(&block) : plugin_set.each_pair
  end

  # @param plugin_name [String]
  # @return [Boolean]
  #
  # @api private
  # @since 2.2.0
  def registered?(plugin_name)
    plugin_set.key?(plugin_name)
  end

  # @param plugin_name [Symbol, String]
  # @param plugin_module [TableSync::Plugins::Abstract]
  # @return [void]
  #
  # @raise [TableSync::AlreadyRegisteredPluginError]
  #
  # @api private
  # @since 2.2.0
  def apply(plugin_name, plugin_module)
    plugin_name = indifferently_accessible_plugin_name(plugin_name)
    raise(TableSync::AlreadyRegisteredPluginError.new(plugin_name)) if registered?(plugin_name)
    plugin_set[plugin_name] = plugin_module
  end

  # @param plugin_name [Symbol, String]
  # @return [TableSync::Plugins::Abstract]
  #
  # @raise [TableSync::UnregisteredPluginError]
  #
  # @api private
  # @since 2.2.0
  def fetch(plugin_name)
    plugin_name = indifferently_accessible_plugin_name(plugin_name)
    raise(TableSync::UnregisteredPluginError.new(plugin_name)) unless registered?(plugin_name)
    plugin_set[plugin_name]
  end

  # @param key [Symbol, String]
  # @return [String]
  #
  # @api private
  # @since 2.2.0
  def indifferently_accessible_plugin_name(plugin_name)
    plugin_name.to_s
  end
end
