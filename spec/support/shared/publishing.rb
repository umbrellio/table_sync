# frozen_string_literal: true

shared_context "with created users" do |quantity|
  before do
    (1..quantity).each do |id|
      DB[:users].insert({
        id: id,
        name: "test#{id}",
        email: "mail#{id}",
        ext_id: id + 100,
        ext_project_id: 12,
        version: 123,
        rest: nil,
      })
    end
  end
end

shared_context "with Sequel ORM" do
  before { TableSync.orm = :sequel }
end
