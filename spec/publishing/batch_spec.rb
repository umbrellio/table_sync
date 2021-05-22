# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Batch do
	let(:original_attributes)   { [{ id: 1, time: Time.current }] }
	let(:serialized_attributes) { [{ id: 1 }] }

  let(:attributes) do
  	{
			object_class: "User",
  		original_attributes: original_attributes,
  		event: :update,
  		headers: { some_arg: 1 },
  		routing_key: "custom_key123",
  	}
  end

	include_examples "publisher#publish_now calls stubbed message with attributes",
		TableSync::Publishing::Message::Batch

	context "#publish_later" do
		let(:job) { double("BatchJob", perform_later: 1) }

		include_examples "publisher#publish_later behaviour"
	end
end
