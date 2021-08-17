# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Batch do
  include_context "with created users", 1

  let(:existing_user)	{ ARecordUser.first }
  let(:original_attributes)   { [{ id: existing_user.id, time: Time.current }] }
  let(:serialized_attributes) { [{ id: existing_user.id }] }
  let(:event)	{ :update }
  let(:object_class)				  { "ARecordUser" }
  let(:routing_key)					  { object_class.tableize }
  let(:headers)					      { { klass: object_class } }

  let(:attributes) do
    {
      object_class: object_class,
      original_attributes: original_attributes,
      event: event,
      headers: headers,
      routing_key: routing_key,
    }
  end

  include_examples "publisher#publish_now with stubbed message",
                   TableSync::Publishing::Message::Batch

  context "real user" do
    context "sequel" do
      let(:object_class) { "SequelUser" }

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
