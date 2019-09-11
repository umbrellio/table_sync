# frozen_string_literal: true

describe "Incomplete events" do
  before do
    DB[:simple_players].delete

    DB[:simple_players].insert(
      external_id: 123,
      internal_id: 456,
      project_id: "prj1",
      version: 0,
      rest: Sequel::Postgres::JSONBHash.new({}),
    )
  end

  let(:handler) do
    Class.new(TableSync::ReceivingHandler) do
      receive("User", to_table: :simple_players) do
        target_keys [:internal_id, :external_id]
      end
    end
  end

  shared_examples "emit event with no target keys" do
    def emit_event(event)
      handler.new(event).call
    end

    context "semi-provided key set" do
      it "fails with corresponding error" do
        expect { emit_event(semi_provided_event) }.to raise_error(
          TableSync::UnprovidedEventTargetKeysError
        )

        expect(DB[:simple_players].count).to eq(1)
      end
    end

    context "empty key set" do
      it "fails with corresponding error" do
        expect { emit_event(empty_event) }.to raise_error(
          TableSync::UnprovidedEventTargetKeysError
        )

        expect(DB[:simple_players].count).to eq(1)
      end
    end
  end

  describe 'incomplete <destroy> event' do
    let(:semi_provided_event) do
      OpenStruct.new(
        data: {
          event: "destroy",
          model: "User",
          attributes: {
            external_id: 123, # NOTE: missing :internal_id attribute
          },
          version: 123,
        },
        project_id: "prj1",
      )
    end

    let(:empty_event) do
      OpenStruct.new(
        data: {
          event: "destroy",
          model: "User",
          attributes: {}, # NOTE: empty key set
          version: 456,
        },
        project_id: "prj1",
      )
    end

    it_behaves_like "emit event with no target keys" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
    end

    it_behaves_like "emit event with no target keys" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
    end
  end

  describe 'incomplete <update> event' do
    let(:semi_provided_event) do
      OpenStruct.new(
        data: {
          event: "update",
          model: "User",
          attributes: {
            id: 123, # NOTE: missing :internal_id attribute (id is mapped to :external_id)
          },
          version: 123,
        },
        project_id: "prj1",
      )
    end

    let(:empty_event) do
      OpenStruct.new(
        data: {
          event: "update",
          model: "User",
          attributes: {}, # NOTE: empty key set
          version: 456,
        },
        project_id: "prj1",
      )
    end

    it_behaves_like "emit event with no target keys" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
    end

    it_behaves_like "emit event with no target keys" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
    end
  end
end
