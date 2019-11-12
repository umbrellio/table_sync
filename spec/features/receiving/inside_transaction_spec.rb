# frozen_string_literal: true

describe "Receiving inside transaction logic" do
  before do
    stub_const("STORAGE", [])
    DB[:players].delete
  end

  def handle(event)
    handler.new(event).call
  rescue StandardError
  end

  shared_examples "update is successful" do
    specify do
      expect { handle(event) }.to change { DB[:players].count }.from(0).to(2)
      expect(STORAGE).to eq([[1234, "project_1"], [5678, "project_1"]])
    end
  end

  shared_examples "update is fails" do
    specify do
      expect { handle(event) }.not_to change { DB[:players].count }
      expect(STORAGE).to eq([])
    end
  end

  let(:handler) do
    Class.new(TableSync::ReceivingHandler) do
      receive("Player", to_table: :players) do
        target_keys [:external_id]
        mapping_overrides id: :external_id
        inside_transaction :after_receive do |wrapped_data|
          wrapped_data.each do |(_model_class, changed_rows)|
            changed_rows.each do |row|
              STORAGE << [row[:external_id], row[:project_id]]
            end
          end
        end
      end
    end
  end

  let(:event) do
    OpenStruct.new(
      data: {
        event: "update",
        model: "Player",
        attributes: [
          {
            id: 1234,
            email: "kek@pek.test",
            project_id: "project_1",
            online_status: false,
          },
          {
            id: 5678,
            email: "kek2@pek.test",
            project_id: "project_1",
            online_status: false,
          },
        ],
        version: 456,
      },
      project_id: "prj1",
    )
  end

  describe "inside transaction logic executed successful" do
    it_behaves_like "update is successful" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
    end

    it_behaves_like "update is successful" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
    end
  end

  describe "inside transaction block can be defined multiple times" do
    before do
      allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel)
      stub_const("OTHER_STORAGE", [])
    end

    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("Player", to_table: :players) do
          target_keys [:external_id]
          mapping_overrides id: :external_id
          inside_transaction :after_receive do |wrapped_data|
            wrapped_data.each do |(_model_class, changed_rows)|
              changed_rows.each do |row|
                STORAGE << [row[:external_id], row[:project_id]]
              end
            end
          end

          inside_transaction :after_receive do |wrapped_data|
            wrapped_data.each do |(_model_class, changed_rows)|
              changed_rows.each do |row|
                OTHER_STORAGE << [row[:external_id], row[:project_id]]
              end
            end
          end
        end
      end
    end

    specify do
      expect { handle(event) }.to change { DB[:players].count }.from(0).to(2)
      expect(STORAGE).to eq([[1234, "project_1"], [5678, "project_1"]])
      expect(OTHER_STORAGE).to eq([[1234, "project_1"], [5678, "project_1"]])
      expect(OTHER_STORAGE).to eq(STORAGE)
    end
  end

  describe "inside transaction block contains error and fails whole transaction " do
    let(:handler) do
      Class.new(TableSync::ReceivingHandler) do
        receive("Player", to_table: :players) do
          target_keys [:external_id]
          mapping_overrides id: :external_id
          inside_transaction :after_receive do |wrapped_data|
            wrapped_data.each do |(_model_class, _changed_rows)|
              raise StandardError
            end
          end
        end
      end
    end

    it_behaves_like "update is fails" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::ActiveRecord) }
    end

    it_behaves_like "update is fails" do
      before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }
    end
  end

  describe "wrong context" do
    before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }

    specify "fails with corresponding error" do
      expect do
        Class.new(TableSync::ReceivingHandler) do
          receive("Player", to_table: :players) do
            inside_transaction(:kek_event) {}
          end
        end
      end.to raise_error(
        TableSync::IncorrectInsideTransactionContextError,
        "Wrong context, available contexts are: [:before_receive, :after_receive]",
      )
    end
  end
end
