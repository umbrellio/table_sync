# frozen_string_literal: true

module TableSync::Publishing::Message
  class Single < Base
    def object
      objects.first
    end

    def params
      TableSync::Publishing::Params::Single.new(object:).construct
    end
  end
end
