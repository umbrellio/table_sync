# frozen_string_literal: true

describe TableSync::Publishing::Helpers::Attributes do
  let(:filter) { described_class.new(original_attributes) }

  shared_examples "filters out unsafe keys/values" do
    specify do
      expect(filter.serialize).to include(expected_attributes)
    end
  end

  describe "#serialize" do
    context "first level" do
      let(:original_attributes) do
        { :id => 1, :time => Time.current, Object.new => 3, "fd" => 2, true => "kek" }
      end

      let(:expected_attributes) { { :id => 1, :fd => 2, true => "kek" } } # string is symbolized

      it_behaves_like "filters out unsafe keys/values"
    end

    context "deep array" do
      let(:original_attributes) { { id: [1, Time.current, "7"] } }
      let(:expected_attributes) { { id: [1, "7"] } }

      it_behaves_like "filters out unsafe keys/values"
    end

    context "deep hash" do
      let(:original_attributes) do
        { id: { safe: :yes, unsafe: Time.current, Time.current => "7" } }
      end
      let(:expected_attributes) { { id: { safe: "yes" } } }

      it_behaves_like "filters out unsafe keys/values"
    end

    context "infinity" do
      let(:original_attributes) { { id: 1, amount: Float::INFINITY } }
      let(:expected_attributes) { { id: 1 } }

      it_behaves_like "filters out unsafe keys/values"
    end

    context "with different base safe types" do
      let(:original_attributes) { { :id => 1, true => "stuff" } }
      let(:expected_attributes) { { true => "stuff" } }

      before do
        stub_const("#{described_class}::BASE_SAFE_JSON_TYPES", [TrueClass, String])
      end

      it_behaves_like "filters out unsafe keys/values"
    end
  end
end
