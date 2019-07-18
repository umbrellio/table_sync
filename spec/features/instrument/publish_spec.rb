# frozen_string_literal: true

class Player
  class << self
    def find_by(*)
      # Stub
    end

    def find(*)
      # Stub
    end

    def lock(*)
      # Stub
      self
    end

    def primary_key
      "external_id"
    end

    def table_name
      :players
    end
  end
end

[TableSync::ORMAdapter::ActiveRecord, TableSync::ORMAdapter::Sequel].each do |orm|
  describe TableSync::Instrument do
    before do
      allow(TableSync).to receive(:orm).and_return(orm)
      allow(TableSync).to receive(:routing_key_callable) { proc { "routing_key_callable" } }
    end

    let(:player)     { double("player", values: attributes, attributes: attributes) }
    let(:publisher)  { publisher_class.new("Player", attributes, state: :updated) }
    let(:events)     { [] }
    let(:event)      { events.first }

    shared_context "processing" do
      before do
        allow(Player).to receive(:find_by).and_return(player)
        allow(Player).to receive(:find).and_return(player)
        allow(Rabbit).to receive(:publish).and_return(nil)

        TableSync.subscribe("tablesync.publish.update") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        publisher.publish_now
      end

      specify { expect(events.count).to eq(1) }
    end

    context "when publish with #{orm}" do
      let(:publisher_class) { TableSync::Publisher }
      let(:attributes)      { { "external_id" => 101, "email" => "email@example.com" } }

      include_context "processing"

      specify do
        expect(event.payload[:count]).to eq(1)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:event]).to eq(:update)
        expect(event.payload[:direction]).to eq(:publish)
      end
    end

    context "when batch publish with #{orm}" do
      let(:publisher_class) { TableSync::BatchPublisher }
      let(:attributes) do
        [1, 2, 3].map { |e| { "external_id" => e, "email" => "email#{e}@example.com" } }
      end

      include_context "processing"

      specify do
        expect(event.payload[:count]).to eq(3)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:event]).to eq(:update)
        expect(event.payload[:direction]).to eq(:publish)
      end
    end
  end
end
