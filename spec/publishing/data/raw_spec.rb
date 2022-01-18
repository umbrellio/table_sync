# frozen_string_literal: true

describe TableSync::Publishing::Data::Raw do
  let(:data)                { described_class.new(**params) }
  let(:model_name)          { "User" }
  let(:attributes_for_sync) { [{ id: 1, asd: "asd" }, { id: 22, time: Time.current }] }
  let(:event)               { :update }
  let(:resolved_event)      { :update }

  let(:params) do
    {
      model_name: model_name,
      attributes_for_sync: attributes_for_sync,
      event: event,
    }
  end

  let(:expected_data) do
    {
      model: model_name,
      attributes: attributes_for_sync,
      version: an_instance_of(Float),
      event: resolved_event,
      metadata: metadata,
    }
  end

  context "with unwrapped attributes for sync" do
    let(:attributes_for_sync) { Hash[id: 1, kek: "pek"] }

    it "wraps attributes in an array" do
      expect(data.construct).to include(attributes: [id: 1, kek: "pek"])
    end
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
