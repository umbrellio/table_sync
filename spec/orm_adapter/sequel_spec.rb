# frozen_string_literal: true

describe TableSync::ORMAdapter::Sequel do
  it_behaves_like "adapter behaviour", SequelUser, CustomSequelUser
end
