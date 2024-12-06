# frozen_string_literal: true

describe TableSync::Publishing::Data::Objects do
  include_context "with created users", 1

  let(:data)                { described_class.new(**params) }
  let(:object_class)        { ARecordUser }
  let(:event)               { :update }
  let(:resolved_event)      { :update }
  let(:objects)             { [object] }
  let(:expected_attributes) { object_class.first.attributes.symbolize_keys }
  let(:expected_model)      { object_class.to_s }

  let(:params) do
    {
      objects: objects,
      event: event,
      custom_version: nil,
    }
  end

  let(:object) do
    TableSync::ORMAdapter::ActiveRecord.new(
      object_class, { id: object_class.first.id }
    ).find
  end

  let(:expected_data) do
    {
      model: expected_model,
      attributes: [expected_attributes],
      version: an_instance_of(Float),
      event: resolved_event,
      metadata: metadata,
    }
  end

  shared_examples "correctly constructs data for message" do
    specify do
      expect(data.construct).to include(expected_data)
    end
  end

  describe "#construct" do
    let(:metadata) { { created: false } }

    context "event -> create" do
      let(:event)    { :create }
      let(:metadata) { { created: true } }

      include_examples "correctly constructs data for message"
    end

    context "event -> update" do
      context "without attributes_for_sync" do
        include_examples "correctly constructs data for message"
      end

      context "attributes_for_sync defined" do
        let(:object_class)        { CustomARecordUser }
        let(:expected_attributes) { { test: "updated" } }

        before do
          allow(object.object).to receive(:attributes_for_sync).and_return(expected_attributes)
        end

        include_examples "correctly constructs data for message"
      end
    end

    context "event -> destroy" do
      let(:event)          { :destroy }
      let(:resolved_event) { :destroy }

      context "without #attributes_for_destroy" do
        include_examples "correctly constructs data for message"
      end

      context "attributes_for_destroy defined" do
        let(:object_class)        { CustomARecordUser }
        let(:expected_attributes) { { test: "destroyed" } }

        before do
          allow(object.object).to receive(:attributes_for_destroy).and_return(expected_attributes)
        end

        include_examples "correctly constructs data for message"
      end
    end

    context "table_sync_model_name defined on object class" do
      let(:object_class)   { CustomARecordUser }
      let(:expected_model) { "CustomARecordModelName111" }

      before do
        allow(object_class).to receive(:table_sync_model_name).and_return(expected_model)
      end

      include_examples "correctly constructs data for message"
    end
  end
end
