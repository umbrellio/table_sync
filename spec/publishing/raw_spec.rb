# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Raw do
  let(:model_name) { "SequelUser" }
  let(:object_class) { model_name }
  let(:event)               { :update }
  let(:routing_key)         { "custom_routing_key" }
  let(:expected_routing_key) { "custom_routing_key" }
  let(:headers) { { some_key: "123" } }
  let(:original_attributes) { [{ id: 1, name: "purum" }] }

  let(:attributes) do
    {
      model_name: model_name,
      original_attributes: original_attributes,
      routing_key: routing_key,
      headers: headers,
      event: event,
      table_name: nil,
      schema_name: nil,
      custom_version: nil,
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

  include_examples "publisher#new without expected fields",
                   TableSync::Publishing::Raw,
                   %i[model_name original_attributes]
end
