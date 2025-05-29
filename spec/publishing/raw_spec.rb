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

  it_behaves_like "publisher#publish_now with stubbed message",
                  TableSync::Publishing::Message::Raw

  it_behaves_like "publisher#publish_now without stubbed message",
                  TableSync::Publishing::Message::Raw

  context "when routing_key is nil" do
    let(:routing_key) { nil }
    let(:expected_routing_key) { "sequel_users" }

    it_behaves_like "publisher#publish_now without stubbed message",
                    TableSync::Publishing::Message::Raw
  end

  it_behaves_like "publisher#new without expected fields",
                  TableSync::Publishing::Raw,
                  %i[model_name original_attributes]
end
