# frozen_string_literal: true

describe TableSync::ConfigDecorator do
  let(:upsert_results) { [] }
  let(:destroy_results) { [] }

  let(:model) do
    model = instance_double "Model",
                            columns: %i[id projects_id name rest version],
                            primary_keys: %i[id projects_id],
                            upsert: upsert_results,
                            destroy: destroy_results

    allow(model).to receive(:transaction).and_yield
    allow(model).to receive(:after_commit).and_yield

    model
  end

  let(:handler) do
    instance_double "Handler",
                    event: :update,
                    model: "User",
                    version: 123,
                    project_id: "pid",
                    data: { id: 1 }
  end

  let(:config) do
    Class.new(TableSync::Config) { add_option(:test_option) }
         .new(model: model)
  end

  let(:decorated_config) { described_class.new(config, handler) }

  it "checks value when option set as static value" do
    config.test_option("test_value")
    expect(decorated_config.test_option).to eq("test_value")
  end

  it "checks value when option set as proc" do
    config.test_option do |event:, model:, version:, project_id:, data:|
      [event, model, version, project_id, data]
    end
    expect(decorated_config.test_option).to eq([:update, "User", 123, "pid", { id: 1 }])
  end

  describe "update" do
    describe "upsert returns []" do
      let(:upsert_results) { [] }

      it "does nothing" do
        key = 0
        config.after_commit(on: :update) { key = 1 }
        decorated_config.update({})
        expect(key).to eq(0)
      end
    end

    describe "upsert returns one row" do
      let(:upsert_results) { [{ a: 1, b: 2 }] }

      it "call callbacks" do
        checks = []

        config.after_commit(on: :update) { |data| checks[0] = data }
        config.after_commit(on: :update) { |data| checks[1] = data }

        decorated_config.update(model => [])

        expect(checks[0]).to eq(upsert_results)
        expect(checks[1]).to eq(upsert_results)
      end
    end

    describe "multi upsert returns many rows" do
      let(:upsert_results) do
        [{ id: 1, projects_id: 1, a: 1, b: 2 }, { id: 2, projects_id: 1, a: 3, b: 4 }]
      end

      it "calls callbacks" do
        checks = []

        config.after_commit(on: :update) { |data| checks[0] = data }
        config.after_commit(on: :update) { |data| checks[1] = data }

        decorated_config.update(model => [])

        expect(checks[0]).to eq(upsert_results)
        expect(checks[1]).to eq(upsert_results)
      end
    end

    describe "multi upsert returns duplicate keys" do
      let(:upsert_results) do
        [{ id: 1, projects_id: 1, a: 1, b: 2 }, { id: 1, projects_id: 1, a: 3, b: 4 }]
      end

      specify do
        expect { decorated_config.update(model => []) }.to raise_error(TableSync::UpsertError)
      end
    end

    describe "upsert returns more than one row" do
      let(:upsert_results) { [{ a: 1 }, { a: 2 }] }

      it "calls callbacks" do
        checks = { a: 0, b: 0 }

        config.after_commit(on: :update) { checks[:a] = 1 }
        config.after_commit(on: :update) { checks[:b] = 1 }

        expect { decorated_config.update(model => []) }.to raise_error(TableSync::UpsertError)
      end
    end
  end

  describe "destroy" do
    let(:checks) { [] }

    before do
      config.after_commit(on: :destroy) { |data| checks[0] = data }
      config.after_commit(on: :destroy) { |data| checks[1] = data }
    end

    describe "destroy returns []" do
      let(:destroy_results) { [] }

      it "does nothing" do
        decorated_config.destroy([])
        expect(checks).to eq([])
      end
    end

    describe "destroy returns one row" do
      let(:destroy_results) { [{ a: 1, b: 2 }] }

      it "calls callbacks" do
        decorated_config.destroy([])
        expect(checks[0]).to eq([{ a: 1, b: 2 }])
        expect(checks[1]).to eq([{ a: 1, b: 2 }])
      end
    end

    describe "destroy returns more than one row" do
      let(:destroy_results) { [{ a: 1 }, { a: 2 }] }

      it "calls callbacks" do
        expect { decorated_config.destroy([]) }.to raise_error(TableSync::DestroyError)
      end
    end
  end
end
