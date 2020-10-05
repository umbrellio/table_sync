# frozen_string_literal: true

describe TableSync::Receiving::Config do
  let(:model) { double("model", columns: [:id, :name, :created_at], primary_keys: :id) }

  describe "#allow_event?" do
    it "sets events like a single value" do
      config = described_class.new(model: model, events: :update)
      expect(config.allow_event?(:update)).to be(true)
    end

    it "sets events like an array value" do
      config = described_class.new(model: model, events: %i[update destroy])
      expect(config.allow_event?(:update)).to be(true)
      expect(config.allow_event?(:destroy)).to be(true)
    end

    it "returns true for :update and :destroy if events is not set" do
      config = described_class.new(model: model)
      expect(config.allow_event?(:update)).to be(true)
      expect(config.allow_event?(:destroy)).to be(true)
      expect(config.allow_event?(:wrong_event)).to be(false)
    end

    it "returns false for wrong event" do
      config = described_class.new(model: model, events: :update)
      expect(config.allow_event?(:destroy)).to be(false)
    end
  end

  describe "options" do
    let(:config) { described_class.new(model: model) }

    describe "#only" do
      it "returns correct default value" do
        expect(config.only).to eq([:id, :name, :created_at])
      end

      it "processes a single value correctly" do
        config.only :id
        expect(config.only).to eq([:id])
      end

      it "raises an error for an invalid single value" do
        expect { config.only :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes an array correctly" do
        config.only [:id, :name]
        expect(config.only).to eq([:id, :name])
      end

      it "processes a list correctly" do
        config.only(:id, :name)
        expect(config.only).to eq([:id, :name])
      end

      it "raises an error for an invalid value in an array" do
        expect { config.only [:id, :wrong_column] }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.only { |target_keys:| target_keys + [:name] }
        expect(config.only.call(target_keys: [:id], data: "data"))
          .to eq([:id, :name])
      end

      it "raises an error for an invalid result from a proc" do
        config.only { [:id, :name, :wrong_column] }
        expect { config.only.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#target_keys" do
      it "returns correct default value" do
        expect(config.target_keys).to eq([:id])
      end

      it "processes a single value correctly" do
        config.target_keys :created_at
        expect(config.target_keys).to eq([:created_at])
      end

      it "raises an error for an invalid single value" do
        expect { config.target_keys :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes an array correctly" do
        config.target_keys [:id, :name]
        expect(config.target_keys).to eq([:id, :name])
      end

      it "processes a list correctly" do
        config.target_keys(:id, :name)
        expect(config.target_keys).to eq([:id, :name])
      end

      it "raises an error for an invalid value in an array" do
        expect { config.target_keys [:id, :wrong_column] }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.target_keys { [:id, :name] }
        expect(config.target_keys.call).to eq([:id, :name])
      end

      it "raises an error for an invalid result from a proc" do
        config.target_keys { [:id, :name, :wrong_column] }
        expect { config.target_keys.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#rest_key" do
      it "returns correct default value" do
        expect(config.rest_key).to eq(:rest)
      end

      it "processes a single value correctly" do
        config.rest_key :name
        expect(config.rest_key).to eq(:name)
      end

      it "processes false as value correctly" do
        config.rest_key false
        expect(config.rest_key).to eq(false)
      end

      it "raises an error for an invalid single value" do
        expect { config.rest_key :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.rest_key { |target_keys:| target_keys.first }
        expect(config.rest_key.call(target_keys: [:id, :name], data: "data")).to eq(:id)
      end

      it "raises an error for an invalid result from a proc" do
        config.rest_key { :wrong_column }
        expect { config.rest_key.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#version_key" do
      it "returns correct default value" do
        expect(config.version_key).to eq(:version)
      end

      it "processes a single value correctly" do
        config.version_key :name
        expect(config.version_key).to eq(:name)
      end

      it "raises an error for an invalid single value" do
        expect { config.version_key :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.version_key { |target_keys:| target_keys.first }
        expect(config.version_key.call(target_keys: [:id, :name], data: "data")).to eq(:id)
      end

      it "raises an error for an invalid result from a proc" do
        config.version_key { [:id, :name] }
        expect { config.version_key.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#except" do
      it "returns correct default value" do
        expect(config.except).to eq([])
      end

      it "processes a single value correctly" do
        config.except :name
        expect(config.except).to eq([:name])
      end

      it "raises an error for an invalid single value" do
        expect { config.except "wrong_value" }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.except { |target_keys:| target_keys.first }
        expect(config.except.call(target_keys: [:id, :name], data: "data")).to eq([:id])
      end

      it "raises an error for an invalid result from a proc" do
        config.except { [:id, :name, "wrong_value"] }
        expect { config.except.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "mapping_overrides" do
      it "returns correct default value" do
        expect(config.mapping_overrides).to eq({})
      end

      it "processes a hash value correctly" do
        config.mapping_overrides(login: :name)
        expect(config.mapping_overrides).to eq({ login: :name })
      end

      it "raises an error for an invalid hash" do
        expect { config.mapping_overrides :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "raises an error for an invalid key in hash" do
        expect { config.mapping_overrides("login" => :name) }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "raises an error for an invalid value in hash" do
        expect { config.mapping_overrides(login: "name") }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.mapping_overrides { |target_keys:| [:gid, :login].zip(target_keys).to_h }
        expect(config.mapping_overrides.call(target_keys: [:id, :name], data: "data"))
          .to eq(gid: :id, login: :name)
      end

      it "raises an error for an invalid result from a proc" do
        config.mapping_overrides { [:id, :name] }
        expect { config.mapping_overrides.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "additional_data" do
      it "returns correct default value" do
        expect(config.additional_data).to eq({})
      end

      it "processes a hash value correctly" do
        config.additional_data(login: "test")
        expect(config.additional_data).to eq({ login: "test" })
      end

      it "raises an error for an invalid hash" do
        expect { config.additional_data :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "raises an error for an invalid key in hash" do
        expect { config.additional_data("login" => :name) }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.additional_data { |target_keys:| target_keys.zip([1, "test"]).to_h }
        expect(config.additional_data.call(target_keys: [:id, :name], data: "data"))
          .to eq(id: 1, name: "test")
      end

      it "raises an error for an invalid result from a proc" do
        config.additional_data { [:id, :name] }
        expect { config.additional_data.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "default_values" do
      it "returns correct default value" do
        expect(config.default_values).to eq({})
      end

      it "processes a hash value correctly" do
        config.default_values(login: "test")
        expect(config.default_values).to eq({ login: "test" })
      end

      it "raises an error for an invalid hash" do
        expect { config.default_values :wrong_column }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "raises an error for an invalid key in hash" do
        expect { config.default_values("login" => :name) }
          .to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.default_values { |target_keys:| target_keys.zip([1, "test"]).to_h }
        expect(config.default_values.call(target_keys: [:id, :name], data: "data"))
          .to eq(id: 1, name: "test")
      end

      it "raises an error for an invalid result from a proc" do
        config.default_values { [:id, :name] }
        expect { config.default_values.call }
          .to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#skip" do
      it "returns correct default value" do
        expect(config.skip).to eq(false)
      end

      it "processes a single value correctly" do
        config.skip true
        expect(config.skip).to eq(true)
      end

      it "raises an error for an invalid single value" do
        expect { config.skip nil }.to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.skip { |target_keys:| target_keys.empty? }
        expect(config.skip.call(target_keys: [:id, :name], data: "data")).to eq(false)
      end

      it "raises an error for an invalid result from a proc" do
        config.skip { "wrong value" }
        expect { config.skip.call }.to raise_error(TableSync::WrongOptionValue)
      end
    end

    describe "#wrap_receiving" do
      it "returns correct default value" do
        expect(config.wrap_receiving).to be_a(Proc)
        test_proc = double("proc")
        expect(test_proc).to receive(:call)
        config.wrap_receiving.call { test_proc.call }
      end

      it "raises an error for a static value" do
        expect { config.wrap_receiving "wrong" }.to raise_error(TableSync::WrongOptionValue)
      end

      it "processes a proc correctly" do
        config.wrap_receiving { |target_keys:| "test" }
        expect(config.wrap_receiving.call(target_keys: [:id, :name], data: "data")).to eq("test")
      end
    end

    %i[before_update after_commit_on_update before_destroy after_commit_on_destroy].each do |option|
      describe "##{option}" do
        it "returns correct default value" do
          expect(config.send(option)).to be_a(Proc)
        end

        it "raises an error for a static value" do
          expect { config.send(option, "wrong value") }.to raise_error(TableSync::WrongOptionValue)
        end

        it "processes a procs correctly" do
          test_proc = double("proc")

          config.send(option) { |data:| test_proc.call(data) }
          config.send(option) { |data:| test_proc.call(data) }
          config.send(option) { |data:| test_proc.call(data) }

          expect(test_proc).to receive(:call).with("data").exactly(3).time

          config.send(option).call(target_keys: [:a], data: "data")
        end
      end
    end
  end
end
