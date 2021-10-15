# frozen_string_literal: true

describe TableSync::Publishing::Params::Single do
  let(:object_class)       { "ARecordUser" }
  let(:attributes)         { default_attributes }
  let(:default_attributes) { { object: object } }
  let(:service)            { described_class.new(**attributes) }

  let(:object) do
    TableSync::Publishing::Helpers::Objects.new(
      object_class: object_class, original_attributes: { id: 1 }, event: :update,
    ).construct_list.first
  end

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

  before do
    DB[:users].insert(
      id: 1, name: "user", email: "user@mail.com", ext_id: 123, ext_project_id: 1,
    )
  end

  describe "#construct" do
    context "default params" do
      let(:expected_values) { default_expected_values }

      include_examples "constructs with expected values"
    end

    context "headers" do
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

      it "calls callable with attributes" do
        expect(TableSync.headers_callable).to receive(:call).with(object_class, object.attributes)
        service.construct
      end

      context "with attrs for headers" do
        let(:object_class) { "CustomARecordUser" }

        before do
          allow(object.object).to receive(
            :attributes_for_headers,
          ).and_return(:attributes_for_headers)
        end

        it "calls callable with attributes" do
          expect(TableSync.headers_callable)
            .to receive(:call).with(object_class, :attributes_for_headers)

          service.construct
        end
      end
    end

    context "routing_key" do
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

      it "calls callable with attributes" do
        expect(TableSync.routing_key_callable)
          .to receive(:call).with(object_class, object.attributes)

        service.construct
      end

      context "with attributes for routing key" do
        let(:object_class) { "CustomARecordUser" }

        before do
          allow(object.object).to receive(
            :attributes_for_routing_key,
          ).and_return(:attributes_for_routing_key)
        end

        it "calls callable with attributes" do
          expect(TableSync.routing_key_callable)
            .to receive(:call).with(object_class, :attributes_for_routing_key)

          service.construct
        end
      end
    end

    context "exchange_name" do
      context "by default" do
        let(:exchange_name)   { "some.project.table_sync" }
        let(:expected_values) { default_expected_values.merge(exchange_name: exchange_name) }

        before { TableSync.exchange_name = exchange_name }

        include_examples "constructs with expected values"
      end
    end
  end
end
