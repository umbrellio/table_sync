# frozen_string_literal: true

describe "Wrap receiving logic" do
  before do
    stub_const("RECEIVING_WRAPPER_RESULTS", [])

    DB[:players].delete

    DB[:players].insert(
      external_id: 123,
      project_id: "prj1",
      email: "test@test.test",
      online_status: true,
      version: 0,
      rest: Sequel::Postgres::JSONBHash.new({}),
    )
  end

  let(:destroy_event) do
    OpenStruct.new(
      data: {
        event: "destroy",
        model: "Player",
        attributes: { id: 123 },
        version: 123,
      },
      project_id: "prj1",
    )
  end

  let(:upsert_event) do
    OpenStruct.new(
      data: {
        event: "update",
        model: "Player",
        attributes: {
          id: 1234,
          email: "kek@pek.test",
          online_status: false,
        },
        version: 456,
      },
      project_id: "prj1",
    )
  end

  shared_examples "invokable receiving" do |model_klass:|
    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("Player", to_table: :players) do
          target_keys [:external_id]
          mapping_overrides id: :external_id

          wrap_receiving do |data, receiving|
            RECEIVING_WRAPPER_RESULTS << data
            receiving.call
          end
        end
      end
    end

    specify "destroy event" do
      expect { handler.new(destroy_event).call }.to change { DB[:players].count }.by(-1)

      expect(RECEIVING_WRAPPER_RESULTS.count).to eq(1)
      received_data = RECEIVING_WRAPPER_RESULTS.first

      expect(received_data.destroy?).to eq(true)
      expect(received_data.update?).to eq(false)

      expect(received_data.event_data).to match(external_id: 123, rest: {}, version: 123)
    end

    specify "upsert event" do
      expect { handler.new(upsert_event).call }.to change { DB[:players].count }.by(1)
      expect(RECEIVING_WRAPPER_RESULTS.count).to eq(1)
      received_data = RECEIVING_WRAPPER_RESULTS.first

      data = received_data.event_data.values.first.first # omg...
      expect(data).to match(
        external_id: 1234, rest: {}, version: 456, email: "kek@pek.test", online_status: false,
      )
    end

    specify "iterable upsert-event data" do
      handler.new(upsert_event).call
      received_data = RECEIVING_WRAPPER_RESULTS.first

      expect(received_data.update?).to eq(true)
      expect(received_data.destroy?).to eq(false)

      received_data.each do |model, data|
        expect(model).to be_a(model_klass)
        expect(data).to be_a(Array)
        expect(data.first).to be_a(Hash)
      end
    end

    specify "iterable destroy-event data" do
      handler.new(destroy_event).call
      received_data = RECEIVING_WRAPPER_RESULTS.first

      expect(received_data.update?).to eq(false)
      expect(received_data.destroy?).to eq(true)

      expect(received_data).to all(be_a(Hash))
    end
  end

  shared_examples "non-invokable receiving" do
    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("Player", to_table: :players) do
          target_keys [:external_id]
          mapping_overrides id: :external_id

          wrap_receiving do |data, _receiving|
            RECEIVING_WRAPPER_RESULTS << data
          end
        end
      end
    end

    specify "destroy event" do
      expect { handler.new(destroy_event).call }.not_to change { DB[:players].count }

      expect(RECEIVING_WRAPPER_RESULTS.count).to eq(1)
      received_data = RECEIVING_WRAPPER_RESULTS.first

      expect(received_data.destroy?).to eq(true)
      expect(received_data.update?).to eq(false)

      expect(received_data.event_data).to match(external_id: 123, rest: {}, version: 123)
    end

    specify "upsert event" do
      expect { handler.new(upsert_event).call }.not_to change { DB[:players].count }

      expect(RECEIVING_WRAPPER_RESULTS.count).to eq(1)
      received_data = RECEIVING_WRAPPER_RESULTS.first
      expect(received_data.update?).to eq(true)
      expect(received_data.destroy?).to eq(false)

      data = received_data.event_data.values.first.first # omg...
      expect(data).to match(
        external_id: 1234, rest: {}, version: 456, email: "kek@pek.test", online_status: false,
      )
    end
  end

  it_behaves_like "invokable receiving", model_klass: TableSync::Model::Sequel do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
  end

  it_behaves_like "invokable receiving", model_klass: TableSync::Model::ActiveRecord do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
  end

  it_behaves_like "non-invokable receiving", model_klass: TableSync::Model::Sequel do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
  end

  it_behaves_like "non-invokable receiving", model_klass: TableSync::Model::ActiveRecord do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
  end
end
