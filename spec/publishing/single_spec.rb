# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Single do
  include_context "with created users", 1

  let(:existing_user)	{ ARecordUser.first }
  let(:original_attributes) { { id: existing_user.id } }
  let(:event) { :update }
  let(:object_class)				{ "ARecordUser" }
  let(:routing_key)					{ object_class.tableize }
  let(:expected_routing_key) { "a_record_users" }
  let(:headers) { { klass: object_class } }
  let(:debounce_time)	{ 30 }

  let(:attributes) do
    {
      object_class: object_class,
      original_attributes: original_attributes,
      event: event,
      debounce_time: debounce_time,
    }
  end

  describe "#publish_now" do
    include_examples "publisher#publish_now with stubbed message",
                     TableSync::Publishing::Message::Single

    context "real user" do
      context "sequel" do
        let(:object_class) { "SequelUser" }
        let(:expected_routing_key) { "sequel_users" }

        include_examples "publisher#publish_now with real user, for given orm",
                         :sequel
      end

      context "when routing key is nil" do
        let(:object_class) { "SequelUser" }
        let(:routing_key) { nil }
        let(:expected_routing_key) { "sequel_users" }

        include_examples "publisher#publish_now with real user, for given orm",
                         :sequel
      end

      context "active_record" do
        include_examples "publisher#publish_now with real user, for given orm",
                         :active_record
      end
    end

    describe "#empty message" do
      let(:original_attributes) { { id: existing_user.id + 100 } }

      it "skips publish" do
        expect(Rabbit).not_to receive(:publish)
        described_class.new(attributes).publish_now
      end
    end
  end

  describe "#publish_later" do
    let(:original_attributes) { { id: 1, time: Time.current } }
    let(:serialized_attributes) { { id: 1 } }
    let(:job)                   { double("Job", perform_later: 1) }

    let(:expected_job_attributes) do
      attributes.merge(original_attributes: serialized_attributes, perform_at: anything)
    end

    include_examples "publisher#publish_later behaviour", :perform_at

    context "debounce" do
      before do
        allow_any_instance_of(described_class).to receive(:job).and_return(job)
        allow(job).to receive(:perform_at)

        allow(TableSync::Publishing::Helpers::Debounce).to receive(:new).and_call_original
      end

      it "calls debounce" do
        expect(TableSync::Publishing::Helpers::Debounce).to receive(:new).with(
          object_class: object_class,
          needle: { id: 1 },
          debounce_time: debounce_time,
          event: event,
        )

        described_class.new(attributes).publish_later
      end

      context "within debounce limit" do
        context "upsert event" do
          let(:event) { :update }

          xit "skips publishing" do
            expect(job).not_to receive(:perform_at).with(any_args)
            described_class.new(attributes).publish_later
          end
        end

        context "destroy event" do
          xit "publishes message" do
            expect(job).to receive(:perform_at).with(any_args)
            described_class.new(attributes).publish_later
          end
        end
      end
    end
  end
end
