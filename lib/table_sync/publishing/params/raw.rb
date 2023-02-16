# frozen_string_literal: true

module TableSync::Publishing::Params
  class Raw < Batch
    attribute :model_name

    alias_method :object_class, :model_name
  end
end
