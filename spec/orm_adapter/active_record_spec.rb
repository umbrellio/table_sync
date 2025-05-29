# frozen_string_literal: true

describe TableSync::ORMAdapter::ActiveRecord do
  it_behaves_like "adapter behaviour", ARecordUser, CustomARecordUser
end
