# frozen_string_literal: true

describe TableSync::Receiving::Model::ActiveRecord do
  subject(:model) { described_class.new(:players) }

  describe "#isolation_level" do
    it { expect(model.isolation_level(:uncommitted)).to eq(:read_uncommitted) }
    it { expect(model.isolation_level(:committed)).to eq(:read_committed) }
    it { expect(model.isolation_level(:repeatable)).to eq(:repeatable_read) }
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

    let(:row) { { external_id: } }

    it "finds and saves an entry" do
      model.find_and_save(row:, target_keys: [primary_key]) do |entry|
        entry.online_status = true
      end
      expect(player.reload.online_status).to be_truthy
    end

    it "does nothing" do
      row = { external_id: external_id + 1 }
      model.find_and_save(row:, target_keys: [primary_key]) do |entry|
        entry.online_status = true
      end
      expect(player.reload.online_status).to be_falsy
    end
  end
end
