# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Raw do
  let(:attributes) do
  	{
			object_class: "NonExistentClass",
  		original_attributes: [{ id: 1, name: "purum" }],
  		routing_key: "custom_routing_key",
  		headers: { some_key: "123" },
  		event: :create,
  	}
  end

	include_examples "publisher#publish_now calls stubbed message with attributes",
		TableSync::Publishing::Message::Raw
end
