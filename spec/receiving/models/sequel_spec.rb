# frozen_string_literal: true

describe TableSync::Receiving::Model::Sequel do
  subject(:model) { described_class.new(:players) }

  describe "#isolation_level" do
    it { expect(model.isolation_level(:uncommitted)).to eq(:uncommitted) }
    it { expect(model.isolation_level(:committed)).to eq(:committed) }
    it { expect(model.isolation_level(:repeatable)).to eq(:repeatable) }
    it { expect(model.isolation_level(:serializable)).to eq(:serializable) }
    it { expect { model.isolation_level(:invalid) }.to raise_error(KeyError) }
  end

  describe "find_and_save" do
    let(:primary_key) { :external_id }
    let(:external_id) { 100_500 }
    let!(:player) do
      model.send(:raw_model).create(
        external_id:,
        email: "email@mail.com",
        online_status: false,
        version: 123.456,
      )
    end

    let(:keys) { { external_id: } }

    it "finds and saves an entry" do
      model.find_and_save(keys:) do |entry|
        entry.online_status = true
      end
      expect(player.reload.online_status).to be_truthy
    end

    it "does nothing" do
      keys = { external_id: external_id + 1 }
      model.find_and_save(keys:) do |entry|
        entry.online_status = true
      end
      expect(player.reload.online_status).to be_falsy
    end
  end
end
