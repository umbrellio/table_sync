# frozen_string_literal: true

# @api private
# @since 2.2.0
module TableSync::Plugins::AccessMixin
  # @param plugin_name [Symbol, String]
  # @return [void]
  #
  # @see TableSync::Plugins
  #
  # @api public
  # @since 2.2.0
  def plugin(plugin_name)
    TableSync::Plugins.load(plugin_name)
  end
  alias_method :enable, :plugin
  alias_method :load, :plugin

  # @return [Array<String>]
  #
  # @see TableSync::Plugins
  #
  # @api public
  # @since 2.2.0
  def plugins
    TableSync::Plugins.names
  end

  # @return [Hash<String,Class<TableSync::Plugins::Abstract>>]
  #
  # @api private
  # @since 2.2.0
  def loaded_plugins
    TableSync::Plugins.loaded_plugins
  end
  alias_method :enabled_plugins, :loaded_plugins

  # @param plugin_name [String, Symbol]
  # @param plugin_klass [Class<TableSync::Plugins::Abstract>]
  # @return [void]
  #
  # @see TableSync::Plugins
  #
  # @api public
  # @since 2.2.0
  def register_plugin(plugin_name, plugin_klass)
    TableSync::Plugins.register_plugin(plugin_name, plugin_klass)
  end
end
