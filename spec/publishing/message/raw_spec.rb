# frozen_string_literal: true

describe TableSync::Publishing::Message::Raw do
  describe "#publish" do
    let(:attributes) do
      {
        model_name: "User",
        original_attributes: [{ id: 1 }],
        routing_key: "users",
        headers: { kek: 1 },
        event: :update,
        custom_version: nil,
      }
    end

    context "with stubbed data and params" do
      let(:data_class)   { TableSync::Publishing::Data::Raw }
      let(:params_class) { TableSync::Publishing::Params::Raw }

      let(:data)   { instance_double(data_class) }
      let(:params) { instance_double(params_class) }

      let(:data_attributes) do
        {
          model_name: attributes[:model_name],
          attributes_for_sync: attributes[:original_attributes],
          event: attributes[:event],
          custom_version: attributes[:custom_version],
        }
      end

      let(:params_attributes) do
        {
          model_name: attributes[:model_name],
          routing_key: attributes[:routing_key],
          headers: attributes[:headers],
        }
      end

      before do
        allow(data_class).to receive(:new).and_return(data)
        allow(params_class).to receive(:new).and_return(params)

        allow(data).to receive(:construct).and_return({})
        allow(params).to receive(:construct).and_return({})
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
