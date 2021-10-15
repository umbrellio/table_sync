# frozen_string_literal: true

describe TableSync::ORMAdapter::ActiveRecord do
  include_examples "adapter behaviour", ARecordUser, CustomARecordUser
end
