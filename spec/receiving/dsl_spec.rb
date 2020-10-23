# frozen_string_literal: true

describe TableSync::Receiving::DSL do
  let(:handler1) { Class.new { extend TableSync::Receiving::DSL } }
  let(:handler2) { Class.new { extend TableSync::Receiving::DSL } }

  describe "#receive" do
    before do
      allow(TableSync).to receive(:receiving_model)
        .and_return(TableSync::Receiving::Model::Sequel)
    end

    it "builds config without a block" do
      handler1.receive("User", to_table: :clients)
      handler1.receive("User", to_table: :players)
      expect(handler1.configs.key?("User")).to eq(true)
      expect(handler1.configs.key?("SomethingElse")).to eq(false)
      expect(handler1.configs["User"]).to be_an(Array)
      expect(handler1.configs["User"].size).to eq(2)
    end

    it "builds config with block" do
      test_proc = double("proc")

      handler1.receive("User", to_table: :clients) do
        mapping_overrides(a: :b)

        additional_data do |project_id:|
          { custom_attr: project_id }
        end

        after_commit_on_update { |data:| test_proc.call(data: data) }
        after_commit_on_update { |project_id:| test_proc.call(project_id: project_id) }

        wrap_receiving { |data:, &block| test_proc.call(data: data, block: block) }
      end

      expect(handler1.configs.key?("User")).to eq(true)
      config = handler1.configs["User"].first
      expect(config.mapping_overrides).to eq(a: :b)
      expect(config.additional_data.call(project_id: "pid")).to eq(custom_attr: "pid")
      expect(config.after_commit_on_update).to be_a(Proc)

      expect(test_proc).to receive(:call).with(data: "some data")
      expect(test_proc).to receive(:call).with(project_id: "some project_id")
      config.after_commit_on_update.call(data: "some data", project_id: "some project_id")

      test_block = proc {}
      expect(test_proc).to receive(:call).with(data: "data", block: test_block)
      config.wrap_receiving.call(data: "data", &test_block)
    end

    it "raises Interface error" do
      model = Object.new

      expect { handler1.receive("User", to_model: model) }.to raise_error(TableSync::InterfaceError)
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
