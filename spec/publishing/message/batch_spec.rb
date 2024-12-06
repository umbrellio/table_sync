# frozen_string_literal: true

describe TableSync::Publishing::Message::Batch do
  describe "#publish" do
    let(:event) { :destroy }

    let(:attributes) do
      {
        object_class: object_class,
        original_attributes: [{ id: 1 }],
        routing_key: "users",
        headers: { kek: 1 },
        event: event,
      }
    end

    let(:object_class) { "ARecordUser" }

    context "with stubbed data and params" do
      let(:data_class)    { TableSync::Publishing::Data::Objects }
      let(:params_class)  { TableSync::Publishing::Params::Batch }
      let(:objects_class) { TableSync::Publishing::Helpers::Objects }

      let(:data)                  { instance_double(data_class) }
      let(:params)                { instance_double(params_class) }
      let(:objects)               { instance_double(objects_class) }
      let(:collection_of_objects) { double(:collection_of_objects) }
      let(:object)                { double(:object) }

      let(:data_attributes) do
        {
          objects: collection_of_objects,
          event: attributes[:event],
          custom_version: nil,
        }
      end

      let(:params_attributes) do
        {
          object_class: attributes[:object_class],
          routing_key: attributes[:routing_key],
          headers: attributes[:headers],
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

        allow(object).to receive(:object_class).and_return(object_class.constantize)
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

    context "with no objects found" do
      let(:event) { :update }

      around do |example|
        before_value = TableSync.raise_on_empty_message

        TableSync.raise_on_empty_message = true

        example.run

        TableSync.raise_on_empty_message = before_value
      end

      it "raises error" do
        expect { described_class.new(attributes).publish }
          .to raise_error(TableSync::NoObjectsForSyncError)
      end
    end
  end
end
