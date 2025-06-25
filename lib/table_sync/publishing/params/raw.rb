# frozen_string_literal: true

module TableSync::Publishing::Params
  class Raw < Batch
    attr_accessor :model_name

    alias_method :object_class, :model_name

    def initialize(attrs = {})
      super
      self.model_name = attrs[:model_name]
    end
  end
end
