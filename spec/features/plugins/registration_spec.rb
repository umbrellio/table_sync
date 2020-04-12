# frozen_string_literal: true

TableSync::Plugins::ExistenceTest = Class.new(TableSync::Plugins::Abstract)
TableSync.register_plugin(:existence_test, TableSync::Plugins::ExistenceTest)

TableSync::Plugins::ARegTest = Class.new(TableSync::Plugins::Abstract)
TableSync::Plugins::BRegTest = Class.new(TableSync::Plugins::Abstract)

describe "Plugins" do
  specify "plugin registration" do
    expect(TableSync::Plugins.names).not_to include("a_reg_test", "b_reg_test")
    expect(TableSync.plugins).not_to        include("a_reg_test", "b_reg_test")

    TableSync.register_plugin(:a_reg_test, TableSync::Plugins::ARegTest)

    expect(TableSync::Plugins.names).to include("a_reg_test")
    expect(TableSync.plugins).to include("a_reg_test")
    expect(TableSync::Plugins.names).not_to include("b_reg_test")
    expect(TableSync.plugins).not_to include("b_reg_test")

    TableSync.register_plugin(:b_reg_test, TableSync::Plugins::BRegTest)

    expect(TableSync::Plugins.names).to include("a_reg_test", "b_reg_test")
    expect(TableSync.plugins).to include("a_reg_test", "b_reg_test")
  end

  specify "incompatabilities" do
    # fails when there is an attempt to register a plugin which already exists
    expect do
      TableSync::Plugins.register_plugin(:existence_test, Object)
    end.to raise_error(TableSync::AlreadyRegisteredPluginError)
    expect do
      TableSync.register_plugin(:existence_test, Object)
    end.to raise_error(TableSync::AlreadyRegisteredPluginError)

    # fails when there is an attempt to load an unregistered plugin
    expect do
      TableSync::Plugins.load(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)
    expect do
      TableSync.plugin(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)
    expect do
      TableSync.load(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)
    expect do
      TableSync.enable(:kek_test_plugin)
    end.to raise_error(TableSync::UnregisteredPluginError)
  end
end
