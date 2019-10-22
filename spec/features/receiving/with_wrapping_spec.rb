# frozen_string_literal: true

describe 'Wrap receiving logic' do
  before do
    stub_const('RECEIVING_WRAP_RESULTS', [])

    DB[:simple_players].delete
    DB[:simple_players].insert(
      external_id: 123,
      internal_id: 456,
      project_id: "prj1",
      version: 0,
      rest: Sequel::Postgres::JSONBHash.new({}),
    )
  end

  let(:destroy_event) do
    OpenStruct.new(
      data: {
        event: "destroy",
        model: "User",
        attributes: { id: 123, internal_id: 456 },
        project_id: 'prj1',
      }
    )
  end

  let(:create_event) do
    OpenStruct.new(
      data: {
        event: "update",
        model: "User",
        attributes: { id: 1235, internal_id: 5512 },
        project_id: 'prj1',
      }
    )
  end

  shared_examples 'invokable receiving' do
    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("User", to_table: :simple_players) do
          target_keys [:internal_id, :external_id]
          mapping_overrides id: :external_id

          wrap_receiving do |data, receiving|
            RECEIVING_WRAP_RESULTS << data
            receiving.call
          end
        end
      end
    end

    specify 'destroy event' do
      handler.new(destroy_event).call

      expect(DB[:simple_players].count).to eq(0)

      expect(RECEIVING_WRAP_RESULTS).to contain_exactly(
        { internal_id: 456, external_id: 123, rest: {}, version: nil }
      )
    end

    specify 'create event' do
      handler.new(create_event).call

      expect(DB[:simple_players].count).to eq(2)
      expect(RECEIVING_WRAP_RESULTS.count).to eq(1)

      receiving_data = RECEIVING_WRAP_RESULTS.first.values.first.first # omg...
      # NOTE: [{ TableSync::Model::Sequel/ActiveRecord => [{ ...data... }] }]

      expect(receiving_data).to match(internal_id: 5512, external_id: 1235, rest: {}, version: nil)
    end
  end

  shared_examples 'non-invokable receiving' do
    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("User", to_table: :simple_players) do
          target_keys [:external_id]
          mapping_overrides id: :external_id

          wrap_receiving do |data, receiving|
            RECEIVING_WRAP_RESULTS << data
          end
        end
      end
    end

    specify 'destroy event' do
      expect { handler.new(destroy_event).call }.not_to change { DB[:simple_players].count }
      expect(RECEIVING_WRAP_RESULTS).to contain_exactly(
        { internal_id: 456, external_id: 123, rest: {}, version: nil }
      )
    end

    specify 'create event' do
      expect { handler.new(create_event).call }.not_to change { DB[:simple_players].count }
      expect(RECEIVING_WRAP_RESULTS.count).to eq(1)
      receiving_data = RECEIVING_WRAP_RESULTS.first.values.first.first # omg...
      # NOTE: [{ TableSync::Model::Sequel/ActiveRecord => [{ ...data... }] }]

      expect(receiving_data).to match(internal_id: 5512, external_id: 1235, rest: {}, version: nil)
    end
  end

  it_behaves_like "invokable receiving" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
  end

  it_behaves_like "invokable receiving" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
  end

  it_behaves_like "non-invokable receiving" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
  end

  it_behaves_like "non-invokable receiving" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
  end
end
