# frozen_string_literal: true

class TableSync::Plugins::ALoadTest < TableSync::Plugins::Abstract
  def self.install!; end
end

class TableSync::Plugins::BLoadTest < TableSync::Plugins::Abstract
  def self.install!; end
end

class TableSync::Plugins::CLoadTest < TableSync::Plugins::Abstract
  def self.install!
    C_TEST_INTERCEPTOR.invoke
  end
end

class TableSync::Plugins::DLoadTest < TableSync::Plugins::Abstract
  def self.install!
    D_TEST_INTERCEPTOR.invoke
  end
end

TableSync.register_plugin(:a_load_test, TableSync::Plugins::ALoadTest)
TableSync.register_plugin(:b_load_test, TableSync::Plugins::BLoadTest)
TableSync.register_plugin(:c_load_test, TableSync::Plugins::CLoadTest)
TableSync.register_plugin(:d_load_test, TableSync::Plugins::DLoadTest)

describe "Plugins" do
  before do
    interceptor = Class.new { def invoke; end }
    stub_const("C_TEST_INTERCEPTOR", interceptor.new)
    stub_const("D_TEST_INTERCEPTOR", interceptor.new)
  end

  describe "installation" do
    specify "plugin loading interface" do
      expect(TableSync::Plugins::ALoadTest).to receive(:load!).exactly(6).times
      expect(TableSync::Plugins::BLoadTest).to receive(:load!).exactly(6).times

      TableSync.load("a_load_test")
      TableSync.load(:a_load_test)
      TableSync.plugin("a_load_test")
      TableSync.plugin(:a_load_test)
      TableSync.enable("a_load_test")
      TableSync.enable(:a_load_test)

      TableSync.load("b_load_test")
      TableSync.load(:b_load_test)
      TableSync.plugin("b_load_test")
      TableSync.plugin(:b_load_test)
      TableSync.enable("b_load_test")
      TableSync.enable(:b_load_test)
    end

    specify "loaded plugins" do
      expect(TableSync.loaded_plugins).not_to include("a_load_test", "b_load_test")

      TableSync.plugin("a_load_test")
      expect(TableSync.loaded_plugins).to include("a_load_test")
      expect(TableSync.loaded_plugins).not_to include("b_load_test")

      TableSync.plugin("b_load_test")
      expect(TableSync.loaded_plugins).to include("a_load_test", "b_load_test")
    end
  end

  specify "loading (loads only one time)" do
    expect(C_TEST_INTERCEPTOR).to receive(:invoke).exactly(1).time
    expect(D_TEST_INTERCEPTOR).to receive(:invoke).exactly(1).time

    TableSync.load("c_load_test")
    TableSync.load(:c_load_test)
    TableSync.plugin("c_load_test")
    TableSync.plugin(:c_load_test)
    TableSync.enable("c_load_test")
    TableSync.enable(:c_load_test)

    TableSync.load("d_load_test")
    TableSync.load(:d_load_test)
    TableSync.plugin("d_load_test")
    TableSync.plugin(:d_load_test)
    TableSync.enable("d_load_test")
    TableSync.enable(:d_load_test)
  end
end
