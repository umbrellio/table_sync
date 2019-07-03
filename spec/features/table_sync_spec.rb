# frozen_string_literal: true

RSpec.describe TableSync do
  describe "#subscribe" do
    specify do
      expect(TableSync::Instrument).to receive(:subscribe)
      TableSync.subscribe("tablesync", &proc {})
    end
  end
end
