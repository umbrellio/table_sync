# frozen_string_literal: true

describe TableSync::DSL do
  let(:handler1) { Class.new { extend TableSync::DSL } }
  let(:handler2) { Class.new { extend TableSync::DSL } }

  describe "#receive" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }

    it "builds config without a block" do
      handler1.receive("User", to_table: :clients)
      handler1.receive("User", to_table: :players)
      expect(handler1.configs.key?("User")).to eq(true)
      expect(handler1.configs.key?("SomethingElse")).to eq(false)
      expect(handler1.configs["User"]).to be_an(Array)
      expect(handler1.configs["User"].size).to eq(2)
    end

    it "builds config with block" do
      callback = proc {}

      handler1.receive("User", to_table: :clients) do
        mapping_overrides(a: :b)

        additional_data do |project_id:|
          { custom_attr: project_id }
        end

        after_commit(on: :update, &callback)
      end

      expect(handler1.configs.key?("User")).to eq(true)
      config = handler1.configs["User"].first
      expect(config.mapping_overrides).to eq(a: :b)
      expect(config.additional_data.call(project_id: "pid")).to eq(custom_attr: "pid")

      callbacks = config.callback_registry.get_callbacks(kind: :after_commit, event: :update)
      expect(callbacks.size).to eq(1)
      expect(callbacks.first.object_id).to eq(callback.object_id)
    end

    describe "inherited handler" do
      before { handler1.receive("User", to_table: :clients) }

      let!(:handler3) { Class.new(handler1) }

      it "inherits configuration" do
        handler3.receive("User", to_table: :players)
        expect(handler1.configs["User"]).to be_an(Array)
        expect(handler3.configs["User"]).to be_an(Array)
        expect(handler1.configs["User"].size).to eq(1)
        expect(handler3.configs["User"].size).to eq(2)
      end
    end
  end
end
