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
    it_behaves_like "method returns correct value", :resolve, :create,  :update
    it_behaves_like "method returns correct value", :resolve, :update,  :update
    it_behaves_like "method returns correct value", :resolve, :destroy, :destroy
  end

  describe "#metadata" do
    it_behaves_like "method returns correct value", :metadata, :create,  { created: true  }
    it_behaves_like "method returns correct value", :metadata, :update,  { created: false }
    it_behaves_like "method returns correct value", :metadata, :destroy, { created: false }
  end

  describe "#destroy?" do
    it_behaves_like "method returns correct value", :destroy?, :create,  false
    it_behaves_like "method returns correct value", :destroy?, :update,  false
    it_behaves_like "method returns correct value", :destroy?, :destroy, true
  end

  describe "#upsert?" do
    it_behaves_like "method returns correct value", :upsert?, :create,  true
    it_behaves_like "method returns correct value", :upsert?, :update,  true
    it_behaves_like "method returns correct value", :upsert?, :destroy, false
  end
end
