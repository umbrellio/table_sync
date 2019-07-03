# frozen_string_literal: true

[TableSync::ORMAdapter::ActiveRecord, TableSync::ORMAdapter::Sequel].each do |orm|
  describe TableSync::Instrument do
    before do
      allow(TableSync).to receive(:orm).and_return(orm)
      allow(TableSync).to receive(:routing_key_callable) { proc { "routing_key_callable" } }
    end

    let(:instrument) { TableSync::Instrument }

    let(:handler) do
      handler = Class.new(TableSync::ReceivingHandler)
      handler.receive("Player", to_table: :players)
      handler.new(data)
    end

    let(:events) { [] }
    let(:event)  { events.first }

    shared_context "processing" do |event|
      before do
        instrument.subscribe(event) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        handler.call
      end

      specify { expect(events.count).to eq(1) }
    end

    context "when recieve update with #{orm}" do
      let(:data) do
        OpenStruct.new(
          data: {
            event: "update",
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

      include_context "processing", "tablesync.receive.update"

      specify do
        expect(event.payload[:count]).to eq(1)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:event]).to eq(:update)
        expect(event.payload[:direction]).to eq(:receive)
      end
    end

    context "when recieve destroy with #{orm}" do
      let!(:player_id) { DB[:players].insert(external_id: 101, email: "email@example.com") }

      let(:data) do
        OpenStruct.new(
          data: {
            event: "destroy",
            model: "Player",
            attributes: {
              external_id: player_id,
            },
            version: 123.34534,
          },
          project_id: "pid",
        )
      end

      include_context "processing", "tablesync.receive.destroy"

      specify do
        expect(event.payload[:count]).to eq(1)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:event]).to eq(:destroy)
        expect(event.payload[:direction]).to eq(:receive)
      end
    end

    context "when batch recieve with #{orm}" do
      let(:data) do
        OpenStruct.new(
          data: {
            event: "update",
            model: "Player",
            attributes: [
              {
                external_id: 100,
                name: "test1",
                nickname: "test1",
                balance: 100,
                email: "mail1@example.com",
              },
              {
                external_id: 101,
                name: "test2",
                nickname: "test2",
                balance: 100,
                email: "mail2@example.com",
              },
            ],
            version: 123.34534,
          },
          project_id: "pid",
        )
      end

      include_context "processing", "tablesync.receive.update"

      specify do
        expect(event.payload[:count]).to eq(2)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:event]).to eq(:update)
        expect(event.payload[:direction]).to eq(:receive)
      end
    end
  end
end
