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

    def db; end
  end
end

[
  TableSync::ORMAdapter::ActiveRecord,
  TableSync::ORMAdapter::Sequel,
].each do |publishing_adapter|
  describe TableSync::Instrument do
    before do
      TableSync.notifier = TableSync::InstrumentAdapter::ActiveSupport

      allow(TableSync).to receive(:publishing_adapter).and_return(publishing_adapter)
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

        ::ActiveSupport::Notifications.subscribe("tablesync.publish.update") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        publisher.publish_now
      end

      specify { expect(events.count).to eq(1) }
    end

    shared_context "custom schema" do
      before do
        if publishing_adapter == TableSync::ORMAdapter::Sequel
          table_name = Sequel[:custom_schema][:players]
        elsif publishing_adapter == TableSync::ORMAdapter::ActiveRecord
          table_name = "custom_schema.players"
        end

        allow(Player).to receive(:table_name).and_return(table_name)
      end
    end

    shared_examples "sync players notification" do |count: 1, schema: "public"|
      specify { expect(events.count).to eq(1) }

      specify do
        expect(event.payload[:count]).to eq(count)
        expect(event.payload[:table]).to eq("players")
        expect(event.payload[:schema]).to eq(schema)
        expect(event.payload[:event]).to eq(:update)
        expect(event.payload[:direction]).to eq(:publish)
      end
    end

    context "when publish with #{publishing_adapter}" do
      let(:publisher_class) { TableSync::Publishing::Publisher }
      let(:attributes)      { { "external_id" => 101, "email" => "email@example.com" } }

      context "default schema" do
        include_context "processing"

        it_behaves_like "sync players notification"
      end

      context "custom schema" do
        include_context "custom schema"
        include_context "processing"

        it_behaves_like "sync players notification", schema: "custom_schema"
      end
    end

    context "when batch publish with #{publishing_adapter}" do
      let(:publisher_class) { TableSync::Publishing::BatchPublisher }
      let(:attributes) do
        [1, 2, 3].map { |e| { "external_id" => e, "email" => "email#{e}@example.com" } }
      end

      context "default schema" do
        include_context "processing"

        it_behaves_like "sync players notification", count: 3
      end

      context "custom schema" do
        include_context "custom schema"
        include_context "processing"

        it_behaves_like "sync players notification", count: 3, schema: "custom_schema"
      end
    end
  end
end
