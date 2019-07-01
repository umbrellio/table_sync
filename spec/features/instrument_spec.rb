# frozen_string_literal: true

describe TableSync::Instrument do
  before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }

  let(:event_type) { "update" }
  let(:update_event) do
    OpenStruct.new(
      data: {
        event: event_type,
        model: "Player",
        attributes: {
          id: 100,
          external_id: 100,
          name: "test1",
          nickname: "test2",
          balance: 100,
          email: "mail@example.com",
        },
        version: 123.34534,
      },
      project_id: "pid",
    )
  end

  let(:instrument) { TableSync::Instrument }

  let(:handler) do
    handler = Class.new(TableSync::ReceivingHandler)
    handler.receive("Player", to_table: :players)
    handler
  end

  context "when update" do
    event = nil

    before do
      instrument.subscribe(/tablesync/) do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
      end

      handler.new(update_event).call
    end

    it do
      expect(event.name).to eq("tablesync.receive.update")

      expect(event.payload[:count]).to eq(1)
      expect(event.payload[:table]).to eq("players")
      expect(event.payload[:event]).to eq("receive.update")
    end
  end
end
