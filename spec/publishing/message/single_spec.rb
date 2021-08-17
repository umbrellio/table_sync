# frozen_string_literal: true

# MOVE TO SUPPORT!

describe TableSync::Publishing::Message::Single do
  describe "#publish" do
    let(:attributes) do
      {
        object_class: object_class,
        original_attributes: [{ id: 1 }],
        routing_key: "users",
        headers: { kek: 1 },
        event: :destroy,
      }
    end

    let(:object_class) { "ARecordUser" }

    context "with stubbed data and params" do
      let(:data_class)    { TableSync::Publishing::Data::Objects }
      let(:params_class)  { TableSync::Publishing::Params::Single }
      let(:objects_class) { TableSync::Publishing::Helpers::Objects }

      let(:data)                  { instance_double(data_class) }
      let(:params)                { instance_double(params_class) }
      let(:objects)               { instance_double(objects_class) }
      let(:collection_of_objects) { double(:collection_of_objects) }
      let(:object)                { double(:object, object_class: object_class.constantize) }

      let(:data_attributes) do
        {
          objects: collection_of_objects,
          event: attributes[:event],
        }
      end

      let(:params_attributes) do
        {
          object: object,
        }
      end

      before do
        allow(data_class).to receive(:new).and_return(data)
        allow(params_class).to receive(:new).and_return(params)
        allow(objects_class).to receive(:new).and_return(objects)

        allow(data).to receive(:construct).and_return({})
        allow(params).to receive(:construct).and_return({})
        allow(objects).to receive(:construct_list).and_return(collection_of_objects)

        allow(collection_of_objects).to receive(:empty?).and_return(false)
        allow(collection_of_objects).to receive(:first).and_return(object)
        allow(collection_of_objects).to receive(:count).and_return(1)
      end

      it "calls data and params with correct attrs" do
        expect(data_class).to receive(:new).with(data_attributes)
        expect(params_class).to receive(:new).with(params_attributes)

        expect(data).to receive(:construct)
        expect(params).to receive(:construct)

        described_class.new(attributes).publish
      end
    end

    it "calls Rabbit#publish" do
      expect(Rabbit).to receive(:publish)

      described_class.new(attributes).publish
    end
  end
end
