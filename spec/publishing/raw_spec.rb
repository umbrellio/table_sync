# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Raw do
  let(:object_class) { "SequelUser" }
  let(:event)               { :update }
  let(:routing_key)         { "custom_routing_key" }
  let(:expected_routing_key) { "custom_routing_key" }
  let(:headers) { { some_key: "123" } }
  let(:original_attributes) { [{ id: 1, name: "purum" }] }

  let(:attributes) do
    {
      object_class: object_class,
      model_name: nil,
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

  context "when routing_key is nil" do
    let(:routing_key) { nil }
    let(:expected_routing_key) { "sequel_users" }

    include_examples "publisher#publish_now without stubbed message",
                     TableSync::Publishing::Message::Raw
  end

  context "when the name of the class does not match the name of the model" do
    let(:object_class) { "User" }

    before { attributes.merge!(object_class: "SequelUser", model_name: "User") }

    include_examples "publisher#publish_now without stubbed message",
                     TableSync::Publishing::Message::Raw
  end
end
