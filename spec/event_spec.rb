# frozen_string_literal: true

describe TableSync::Event do
  let(:service) { TableSync::Event.new(event) }

  context "invalid event" do
    let(:event) { :invalid_event }

    it "raises error" do
      expect { service }.to raise_error(TableSync::EventError)
    end
  end

  shared_examples "method returns correct value" do |meth, raw_event, value|
    context "#{meth} - #{raw_event}" do
      let(:event) { raw_event }

      it "returns #{value}" do
        expect(service.public_send(meth)).to eq(value)
      end
    end
  end

  describe "#resolve" do
    include_examples "method returns correct value", :resolve, :create,  :update
    include_examples "method returns correct value", :resolve, :update,  :update
    include_examples "method returns correct value", :resolve, :destroy, :destroy
  end

  describe "#metadata" do
    include_examples "method returns correct value", :metadata, :create,  { created: true  }
    include_examples "method returns correct value", :metadata, :update,  { created: false }
    include_examples "method returns correct value", :metadata, :destroy, { created: false }
  end

  describe "#destroy?" do
    include_examples "method returns correct value", :destroy?, :create,  false
    include_examples "method returns correct value", :destroy?, :update,  false
    include_examples "method returns correct value", :destroy?, :destroy, true
  end

  describe "#upsert?" do
    include_examples "method returns correct value", :upsert?, :create,  true
    include_examples "method returns correct value", :upsert?, :update,  true
    include_examples "method returns correct value", :upsert?, :destroy, false
  end
end
