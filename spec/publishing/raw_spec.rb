# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Raw do
  let(:object_class) { "SequelUser" }
  let(:event)               { :update }
  let(:routing_key)         { "custom_routing_key" }
  let(:headers) { { some_key: "123" } }
  let(:original_attributes) { [{ id: 1, name: "purum" }] }

  let(:attributes) do
    {
      object_class: object_class,
      original_attributes: original_attributes,
      routing_key: routing_key,
      headers: headers,
      event: event,
    }
  end

  let(:expected_object_data) { original_attributes }

  include_examples "publisher#publish_now with stubbed message",
                   TableSync::Publishing::Message::Raw

  include_examples "publisher#publish_now without stubbed message",
                   TableSync::Publishing::Message::Raw
end
