# frozen_string_literal: true

module TableSync::Publishing::Params
  class Raw < Batch
    include Tainbox

    attribute :model_name
    attribute :object_class, default: -> { model_name }, writer: false
  end
end
