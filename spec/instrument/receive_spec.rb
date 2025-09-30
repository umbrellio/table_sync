# frozen_string_literal: true

[
  TableSync::Receiving::Model::ActiveRecord,
  TableSync::Receiving::Model::Sequel,
].each do |receiving_model|
  describe TableSync::Instrument do
    before do
      TableSync.notifier = TableSync::InstrumentAdapter::ActiveSupport

      allow(TableSync).to receive(:receiving_model).and_return(receiving_model)
      allow(TableSync).to receive(:routing_key_callable) { proc { "routing_key_callable" } }

      DB.run <<~SQL
        INSERT INTO players (external_id, project_id, email, online_status, version)
        VALUES (1, 'ab', 'foo@example.com', 't', 100);
        INSERT INTO custom_schema.clubs (id, name, position, version)
        VALUES (10, 'Real Madrid', 2, 100);
      SQL
    end

    let(:custom_schema_table) do
      if receiving_model == TableSync::Receiving::Model::ActiveRecord
        "custom_schema.clubs"
      elsif receiving_model == TableSync::Receiving::Model::Sequel
        Sequel[:custom_schema][:clubs]
      end
    end

    let(:handler) do
      handler = Class.new(TableSync::Receiving::Handler)
      handler.receive("Player", to_table: :players)
      handler.receive("Club", to_table: custom_schema_table)
      handler.new(data)
    end

    let(:events) { [] }
    let(:event)  { events.first }

    shared_context "processing" do |event|
      before do
        ActiveSupport::Notifications.subscribe(event) do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        handler.call
      end
    end

    shared_examples "sync notification" do |table:, count: 1, schema: "public", event_type: :update|
      specify { expect(events.count).to eq(1) }

      specify do
        expect(event.payload[:count]).to eq(count)
        expect(event.payload[:table]).to eq(table)
        expect(event.payload[:schema]).to eq(schema)
        expect(event.payload[:event]).to eq(event_type)
        expect(event.payload[:direction]).to eq(:receive)
      end
    end

    context "when recieve update with #{receiving_model}" do
      include_context "processing", "tablesync.receive.update"

      context "default schema" do
        let(:data) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "Player",
              attributes: {
                id: 1,
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

        it_behaves_like "sync notification", table: "players"
      end

      context "custom schema" do
        let(:data) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "Club",
              attributes: {
                id: 10,
                name: "Real Madrid",
                position: 1,
              },
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it_behaves_like "sync notification", table: "clubs", schema: "custom_schema"
      end
    end

    context "when recieve destroy with #{receiving_model}" do
      include_context "processing", "tablesync.receive.destroy"

      context "default schema" do
        let(:data) do
          OpenStruct.new(
            data: {
              event: "destroy",
              model: "Player",
              attributes: {
                external_id: 1,
                email: "some",
              },
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it_behaves_like "sync notification", table: "players", event_type: :destroy
      end

      context "custom schema" do
        let(:data) do
          OpenStruct.new(
            data: {
              event: "destroy",
              model: "Club",
              attributes: {
                id: 10,
              },
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it_behaves_like "sync notification", table: "clubs", schema: "custom_schema",
                                             event_type: :destroy
      end
    end

    context "when batch recieve with #{receiving_model}" do
      include_context "processing", "tablesync.receive.update"

      context "default schema" do
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

        it_behaves_like "sync notification", table: "players", count: 2
      end

      context "custom schema" do
        let(:data) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "Club",
              attributes: [
                {
                  id: 100,
                  name: "Barcelona",
                },
                {
                  id: 101,
                  name: "Atletico Madrid",
                },
              ],
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it_behaves_like "sync notification", table: "clubs", schema: "custom_schema", count: 2
      end
    end
  end
end
