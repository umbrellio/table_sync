# frozen_string_literal: true

describe TableSync::Config do
  let(:model) do
    instance_double "Model",
                    columns: %i[id projects_id name rest version],
                    primary_keys: %i[id projects_id]
  end

  let(:config) { described_class.new(model: model) }

  it "checks default values" do
    expect(config.additional_data).to eq({})
    expect(config.events).to eq(nil)
    expect(config.mapping_overrides).to eq({})
    expect(config.only).to eq([:id, :projects_id, :name, :rest, :version])
    expect(config.rest_key).to eq(:rest)
    expect(config.target_keys).to eq([:id, :projects_id])
    expect(config.version_key).to eq(:version)
  end

  it "sets an option as static value" do
    expect(config.additional_data).to eq({})
    config.additional_data(a: 1, b: 2)
    expect(config.additional_data).to eq(a: 1, b: 2)
  end

  describe "sets an option as a proc" do
    it "without args" do
      expect(config.additional_data).to eq({})

      config.additional_data { :test_value }

      expect(config.additional_data.call).to eq(:test_value)
      expect(config.additional_data.call(a: 1, b: 2)).to eq(:test_value)
    end

    it "with args" do
      expect(config.additional_data).to eq({})

      config.additional_data { |data:| "test_#{data}" }

      expect(config.additional_data.call(data: "123")).to eq("test_123")
      expect(config.additional_data.call(data: "321", a: 1, b: 2)).to eq("test_321")
      expect { config.additional_data.call }.to raise_error(ArgumentError)
    end
  end

  describe "validation for static values" do
    it "#only" do
      config.only(:id)
      expect(config.only).to eq([:id])

      config.only("id")
      expect(config.only).to eq([:id])

      config.only(:id, :name)
      expect(config.only).to eq(%i[id name])

      config.only("id", "name")
      expect(config.only).to eq(%i[id name])

      config.only(%w[id name])
      expect(config.only).to eq(%i[id name])

      expect { config.only(%w[id nonexistent]) }.to raise_error(Exception)
    end

    it "#target_keys" do
      config.target_keys(:id)
      expect(config.target_keys).to eq([:id])

      config.target_keys("id")
      expect(config.target_keys).to eq([:id])

      config.target_keys(:id, :name)
      expect(config.target_keys).to eq(%i[id name])

      config.target_keys("id", "name")
      expect(config.target_keys).to eq(%i[id name])

      config.target_keys(%w[id name])
      expect(config.target_keys).to eq(%i[id name])

      expect { config.target_keys(%w[id nonexistent]) }.to raise_error(Exception)
    end

    it "#rest_key" do
      config.rest_key(:name)
      expect(config.rest_key).to eq(:name)

      config.rest_key("name")
      expect(config.rest_key).to eq(:name)

      expect { config.rest_key(:nonexistent) }.to raise_error(Exception)
    end

    it "#version_key" do
      config.version_key(:name)
      expect(config.version_key).to eq(:name)

      config.version_key("name")
      expect(config.version_key).to eq(:name)

      expect { config.version_key(:nonexistent) }.to raise_error(Exception)
    end
  end

  describe "#allow_event?" do
    describe "when option of events is nil" do
      it "allows all events" do
        config = described_class.new(model: model)
        expect(config.allow_event?("test")).to eq(true)
        expect(config.allow_event?(:test)).to eq(true)

        config = described_class.new(model: model, events: nil)
        expect(config.allow_event?("test")).to eq(true)
        expect(config.allow_event?(:test)).to eq(true)
      end
    end

    describe "when option of events is not null" do
      it "allows only set events" do
        config = described_class.new(model: model, events: :update)
        expect(config.allow_event?("update")).to eq(false)
        expect(config.allow_event?(:update)).to eq(true)

        expect(config.allow_event?("destroy")).to eq(false)
        expect(config.allow_event?(:destroy)).to eq(false)

        config = described_class.new(model: model, events: "update")
        expect(config.allow_event?("update")).to eq(false)
        expect(config.allow_event?(:update)).to eq(true)

        expect(config.allow_event?("destroy")).to eq(false)
        expect(config.allow_event?(:destroy)).to eq(false)

        config = described_class.new(model: model, events: %w[update create])
        expect(config.allow_event?(:update)).to eq(true)
        expect(config.allow_event?(:create)).to eq(true)
        expect(config.allow_event?(:destroy)).to eq(false)
      end
    end
  end

  describe "callbacks" do
    let(:callback_registry) { config.callback_registry }

    specify "#before_commit" do
      expect(callback_registry.get_callbacks(kind: :before_commit, event: :update)).to eq([])

      pr = proc {}

      config.before_commit(on: :update, &pr)

      expect(callback_registry.get_callbacks(kind: :before_commit, event: :update)).to eq([pr])
    end

    specify "#after_commit" do
      expect(callback_registry.get_callbacks(kind: :after_commit, event: :update)).to eq([])

      pr = proc {}

      config.after_commit(on: :update, &pr)

      expect(callback_registry.get_callbacks(kind: :after_commit, event: :update)).to eq([pr])
    end
  end
end
