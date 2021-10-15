# frozen_string_literal: true

describe TableSync::ORMAdapter::Sequel do
  include_examples "adapter behaviour", SequelUser, CustomSequelUser
end
