# frozen_string_literal: true

describe TableSync::Publishing::Helpers::Objects do
  include_context "with created users", 1
  include_context "with Sequel ORM"

  let(:objects) { described_class.new(params) }

  let(:params) do
    {
      object_class: "SequelUser",
      original_attributes: original_attributes,
      event: event,
    }
  end

  describe "#construct_list" do
    context "event -> update" do
      let(:event)               { :update }
      let(:max_id)              { SequelUser.max(:id) + 1000 }
      let(:user_id)             { SequelUser.first.id }
      let(:original_attributes) { [ { id: user_id }, { id: max_id }] }
      let(:found_ids)           { objects.construct_list.map { |i| i.object.id } }

      it "finds existing objects" do
        expect(found_ids).to include(user_id)
      end

      it "strips the list of missing objects" do
        expect(found_ids).not_to include(max_id)
      end
    end

    context "event -> destroy" do
      let(:event)               { :destroy }
      let(:original_attributes) { [ { id: 100 }, { id: 123 }] }
      let(:initialized_ids)     { objects.construct_list.map { |i| i.object.id } }

      it "initializes objects with given data" do
        expect(initialized_ids).to include(*original_attributes.map(&:values).flatten)
      end
    end
  end
end
