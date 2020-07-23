# frozen_string_literal: true

describe TableSync::ConfigDecorator do
  let(:upsert_results)  { [] }
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
    end

    context "destroy states" do
      shared_examples "does_nothing" do
        specify do
          decorated_config.destroy(target_attributes)
          expect(checks).to eq([])
        end
      end

      shared_examples "throws DestroyError" do
        specify do
          expect do
            decorated_config.destroy(target_attributes)
          end.to raise_error(TableSync::DestroyError)
        end
      end

      shared_examples "calls after_commit for destroyed rows" do
        specify do
          decorated_config.destroy(target_attributes)
          expect(checks[0]).to eq(destroy_results)
        end
      end

      context "batch" do
        let(:target_attributes) { [{ id: 1, projects_id: 1 }, { id: 2, projects_id: 2 }] }

        context "destroyed nothing" do
          include_examples "does_nothing"
        end

        context "destroyed more rows than the size of target_attributes" do
          let(:destroy_results) { [{ id: 1 }, { id: 2 }, { id: 3 }] }

          include_examples "throws DestroyError"
        end

        context "destroyed less rows than the size of target attributes" do
          let(:destroy_results)   { [{ id: 1 }] }

          include_examples "calls after_commit for destroyed rows"
        end

        context "destroyed number of rows equal to the size of target attributes" do
          let(:destroy_results)   { [{ id: 1 }, { id: 2 }] }

          include_examples "calls after_commit for destroyed rows"
        end
      end

      context "single" do
        let(:target_attributes) { [{ id: 1, projects_id: 1 }] }

        context "destroyed nothing" do
          include_examples "does_nothing"
        end

        context "destroyed more rows than the size of target_attributes" do
          let(:destroy_results) { [{ id: 1, projects_id: 1 }, { id: 2, projects_id: 2 }] }

          include_examples "throws DestroyError"
        end
      end
    end
  end
end
