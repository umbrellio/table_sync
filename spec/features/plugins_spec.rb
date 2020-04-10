# frozen_string_literal: true

describe "Plugins" do
  specify "plguin regsitration, load and resolving" do
    # plugins are not registered
    expect(TableSync::Plugins.names).not_to include("internal_test_plugin", "external_test_plugin")
    expect(TableSync.plugins).not_to        include("internal_test_plugin", "external_test_plugin")

    InternalTestPluginInterceptor = Class.new { def self.invoke; end }
    ExternalTestPluginInterceptor = Class.new { def self.call; end }

    module TableSync::Plugins
      class InternalTestPlugin < Abstract
        def self.install!
          InternalTestPluginInterceptor.invoke
        end
      end

      class ExternalTestPlugin < Abstract
        def self.install!
          ExternalTestPluginInterceptor.call
        end
      end

      # register new plugins
      register_plugin(:internal_test_plugin, InternalTestPlugin)
      register_plugin(:external_test_plugin, ExternalTestPlugin)
    end

    # plugins are registered
    expect(TableSync::Plugins.names).to include("internal_test_plugin", "external_test_plugin")
    expect(TableSync.plugins).to        include("internal_test_plugin", "external_test_plugin")

    # new plugins is not included in #loaded_plugins list
    expect(TableSync.loaded_plugins).not_to include("internal_test_plugin")
    expect(TableSync.loaded_plugins).not_to include("external_test_plugin")
    expect(TableSync.enabled_plugins).not_to include("internal_test_plugin")
    expect(TableSync.enabled_plugins).not_to include("external_test_plugin")
    expect(TableSync.loaded_plugins).to eq(TableSync.enabled_plugins)

    # plugin can be loaded
    expect(InternalTestPluginInterceptor).to receive(:invoke).exactly(4).times
    TableSync::Plugins.load(:internal_test_plugin)
    TableSync::Plugins.load("internal_test_plugin")
    TableSync.plugin(:internal_test_plugin)
    TableSync.plugin("internal_test_plugin")
    expect(TableSync.loaded_plugins).to include("internal_test_plugin")
    expect(TableSync.loaded_plugins).not_to include("external_test_plugin")
    expect(TableSync.enabled_plugins).to include("internal_test_plugin")
    expect(TableSync.enabled_plugins).not_to include("external_test_plugin")
    expect(TableSync.loaded_plugins).to eq(TableSync.enabled_plugins)

    # plugin can be loaded
    expect(ExternalTestPluginInterceptor).to receive(:call).exactly(4).times
    TableSync::Plugins.load(:external_test_plugin)
    TableSync::Plugins.load("external_test_plugin")
    TableSync.enable(:external_test_plugin)
    TableSync.enable("external_test_plugin")
    expect(TableSync.loaded_plugins).to include("external_test_plugin")
    expect(TableSync.loaded_plugins).to include("internal_test_plugin")
    expect(TableSync.enabled_plugins).to include("external_test_plugin")
    expect(TableSync.enabled_plugins).to include("internal_test_plugin")
    expect(TableSync.loaded_plugins).to eq(TableSync.enabled_plugins)

    # fails when there is an attempt to register a plugin which is already exist
    expect do
      module TableSync::Plugins
        register_plugin(:internal_test_plugin, Object)
      end
    end.to raise_error(TableSync::AlreadyRegisteredPluginError)

    # fails when there is an attempt to register a plugin which is already exist
    expect do
      module TableSync::Plugins
        register_plugin(:external_test_plugin, Object)
      end
    end.to raise_error(TableSync::AlreadyRegisteredPluginError)

    # fails when there is an attempt to load an unregistered plugin
    expect do
      TableSync::Plugins.load(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)

    # fails when there is an attempt to load an unregistered plugin
    expect do
      TableSync.plugin(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)
  end
end
