# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Batch do
  include_context "with created users", 1

  let(:existing_user)	{ ARecordUser.first }
  let(:original_attributes)   { [{ id: existing_user.id, time: Time.current }] }
  let(:serialized_attributes) { [{ id: existing_user.id }] }
  let(:event)	{ :update }
  let(:object_class)				  { "ARecordUser" }
  let(:routing_key)					  { object_class.tableize }
  let(:expected_routing_key) { "a_record_users" }
  let(:headers) { { klass: object_class } }

  let(:attributes) do
    {
      object_class:,
      original_attributes:,
      event:,
      headers:,
      routing_key:,
      custom_version: nil,
    }
  end

  include_examples "publisher#publish_now with stubbed message",
                   TableSync::Publishing::Message::Batch
  include_examples "publisher#new without expected fields",
                   TableSync::Publishing::Batch,
                   %i[object_class original_attributes]

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

  describe "#publish_later" do
    let(:job) { double("BatchJob", perform_at: 1) }

    let(:expected_job_attributes) do
      attributes.merge(original_attributes: serialized_attributes)
    end

    include_examples "publisher#publish_later behaviour", :perform_later
  end
end
