# frozen_string_literal: true

RSpec.describe TableSync::Publishing::Raw do
  let(:model_name) { "SequelUser" }
  let(:object_class) { model_name }
  let(:event)               { :update }
  let(:routing_key)         { "custom_routing_key" }
  let(:expected_routing_key) { "custom_routing_key" }
  let(:headers) { { some_key: "123" } }
  let(:original_attributes) { [{ id: 1, name: "purum" }] }
  let(:table_name) { "sequel_users" }
  let(:schema_name) { "public" }

  let(:attributes) do
    {
      model_name:,
      original_attributes:,
      routing_key:,
      headers:,
      event:,
      table_name:,
      schema_name:,
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
                   %i[model_name original_attributes table_name schema_name]
end
