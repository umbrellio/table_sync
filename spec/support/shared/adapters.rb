# frozen_string_literal: true

shared_examples "adapter behaviour" do |klass, custom_klass|
  include_context "with created users", 1

  let(:adapter)         { described_class.new(object_class, object_data).find }
  let(:object_class)    { klass }
  let(:existing_object) { object_class.first }
  let(:object_data)     { { id: existing_object.id, email: "email" } }

  shared_examples "returns expected_attributes for method" do |meth|
    it meth do
      expect(adapter.send(meth)).to include(expected_attributes)
    end
  end

  describe "#initialize" do
    context "object data without complete primary key" do
      let(:object_data) { { email: "email" } }

      it "raises error" do
        expect { adapter }.to raise_error(TableSync::NoPrimaryKeyError)
      end
    end
  end

  describe "#init" do
    let(:object_data) { { id: existing_object.id + 100 } }

    it "initializes @object with new instance and returns self" do
      expect(adapter.object).to eq(nil)

      adapter.init

      expect(adapter.object.id).to eq(existing_object.id + 100)
    end
  end

  describe "#find" do
    context "if object exists" do
      it "initializes @object with found object and returns self" do
        expect(adapter.object.id).to eq(existing_object.id)
        expect(adapter.object.class).to eq(object_class)
      end
    end

    context "if object doesn't exist" do
      let(:object_data) { { id: existing_object.id + 100 } }

      it "initializes @object with nil and returns self" do
        expect(adapter.object).to eq(nil)
      end
    end
  end

  describe "#needle" do
    it "returns pk attributes from object_data" do
      expect(adapter.needle).to eq({ id: existing_object.id })
    end
  end

  describe "#primary_key_columns" do
    it "returns array of symbolized pk column names" do
      expect(adapter.primary_key_columns).to eq([:id])
    end
  end

  describe "#attributes_for_update" do
    context "object responds to method" do
      let(:expected_attributes) { { custom: "data" } }
      let(:object_class)        { custom_klass }

      before do
        allow(adapter.object).to receive(:attributes_for_sync).and_return(expected_attributes)
      end

      include_examples "returns expected_attributes for method", :attributes_for_update
    end

    context "object DOESN'T respond to method" do
      let(:expected_attributes) { adapter.attributes }

      include_examples "returns expected_attributes for method", :attributes_for_update
    end
  end

  describe "#attributes_for_destroy" do
    context "object responds to method" do
      let(:expected_attributes) { { custom: "data" } }
      let(:object_class)        { custom_klass }

      before do
        allow(adapter.object).to receive(:attributes_for_destroy).and_return(expected_attributes)
      end

      include_examples "returns expected_attributes for method", :attributes_for_destroy
    end

    context "object DOESN'T respond to method" do
      let(:expected_attributes) { adapter.needle }

      include_examples "returns expected_attributes for method", :attributes_for_destroy
    end
  end

  describe "#attributes_for_routing_key" do
    context "object responds to method" do
      let(:expected_attributes) { { custom: "data" } }
      let(:object_class)        { custom_klass }

      before do
        allow(adapter.object).to receive(
          :attributes_for_routing_key,
        ).and_return(expected_attributes)
      end

      include_examples "returns expected_attributes for method", :attributes_for_routing_key
    end

    context "object DOESN'T respond to method" do
      let(:expected_attributes) { adapter.attributes }

      include_examples "returns expected_attributes for method", :attributes_for_routing_key
    end
  end

  describe "#attributes_for_headers" do
    context "object responds to method" do
      let(:expected_attributes) { { custom: "data" } }
      let(:object_class)        { custom_klass }

      before do
        allow(adapter.object).to receive(:attributes_for_headers).and_return(expected_attributes)
      end

      include_examples "returns expected_attributes for method", :attributes_for_headers
    end

    context "object DOESN'T respond to method" do
      let(:expected_attributes) { adapter.attributes }

      include_examples "returns expected_attributes for method", :attributes_for_headers
    end
  end

  describe "#empty?" do
    context "without object" do
      let(:object_data) { { id: existing_object.id + 100 } }

      it "returns true" do
        expect(adapter.empty?).to eq(true)
      end
    end

    context "with object" do
      it "returns false" do
        expect(adapter.empty?).to eq(false)
      end
    end
  end

  describe "#attributes" do
    let(:expected_values) do
      DB[:users].where(id: existing_object.id).naked.all.first
    end

    it "returns symbolized attributes of an object" do
      expect(adapter.attributes).to include(expected_values)
    end
  end
end
