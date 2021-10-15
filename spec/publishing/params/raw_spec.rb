# frozen_string_literal: true

describe TableSync::Publishing::Params::Raw do
  let(:object_class)       { "User" }
  let(:attributes)         { default_attributes }
  let(:default_attributes) { { object_class: object_class } }
  let(:service)            { described_class.new(attributes) }

  let(:default_expected_values) do
    {
      confirm_select: true,
      realtime: true,
      event: :table_sync,
    }
  end

  shared_examples "constructs with expected values" do
    specify do
      expect(service.construct).to include(expected_values)
    end
  end

  shared_examples "raises callable error" do |error|
    specify do
      expect { service.construct }.to raise_error(error)
    end
  end

  describe "#construct" do
    context "default params" do
      let(:expected_values) { default_expected_values }

      include_examples "constructs with expected values"
    end

    context "headers" do
      context "from attributes" do
        let(:headers)         { { custom: "kek" } }
        let(:attributes)      { default_attributes.merge(headers: headers) }
        let(:expected_values) { default_expected_values.merge(headers: headers) }

        include_examples "constructs with expected values"
      end

      context "calculated" do
        let(:expected_values) do
          default_expected_values.merge(headers: { object_class: object_class })
        end

        before do
          TableSync.headers_callable = -> (object_class, _atrs) { { object_class: object_class } }
        end

        include_examples "constructs with expected values"
      end

      context "without headers callable" do
        before { TableSync.headers_callable = nil }

        include_examples "raises callable error", TableSync::NoCallableError
      end
    end

    context "routing_key" do
      context "from attributes" do
        let(:routing_key)     { "custom_routing_key" }
        let(:attributes)      { default_attributes.merge(routing_key: routing_key) }
        let(:expected_values) { default_expected_values.merge(routing_key: routing_key) }

        include_examples "constructs with expected values"
      end

      context "calculated" do
        let(:expected_values) do
          default_expected_values.merge(routing_key: object_class)
        end

        before do
          TableSync.routing_key_callable = -> (object_class, _atrs) { object_class }
        end

        include_examples "constructs with expected values"
      end

      context "without routing_key callable" do
        before { TableSync.routing_key_callable = nil }

        include_examples "raises callable error", TableSync::NoCallableError
      end
    end

    context "exchange_name" do
      context "from attributes" do
        let(:exchange_name)   { "custom_exchange_name" }
        let(:attributes)      { default_attributes.merge(exchange_name: exchange_name) }
        let(:expected_values) { default_expected_values.merge(exchange_name: exchange_name) }

        include_examples "constructs with expected values"
      end

      context "by default" do
        let(:exchange_name)   { "some.project.table_sync" }
        let(:expected_values) { default_expected_values.merge(exchange_name: exchange_name) }

        before { TableSync.exchange_name = exchange_name }

        include_examples "constructs with expected values"
      end
    end
  end
end
