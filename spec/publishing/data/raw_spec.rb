# frozen_string_literal: true

describe TableSync::Publishing::Data::Raw do
  let(:data)                { described_class.new(**params) }
  let(:object_class)        { "User" }
  let(:attributes_for_sync) { [{ id: 1, asd: "asd" }, { id: 22, time: Time.current }] }
  let(:event)               { :update }

  let(:params) do
    {
      object_class: object_class,
      attributes_for_sync: attributes_for_sync,
      event: event,
    }
  end

  let(:expected_data) do
    {
      model: object_class,
      attributes: attributes_for_sync,
      version: an_instance_of(Float),
      event: event,
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

    include_examples "correctly constructs data for message"

    context "event -> create" do
      let(:event)    { :create }
      let(:metadata) { { created: true } }

      include_examples "correctly constructs data for message"
    end
  end
end
