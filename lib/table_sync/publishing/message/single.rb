# frozen_string_literal: true

module TableSync::Publishing::Message
  class Single < Base
    attr_accessor :headers

    def initialize(params = {})
      super

      self.headers = params[:headers]
    end

    def object
      objects.first
    end

    def params
      TableSync::Publishing::Params::Single.new(object:, headers:).construct
    end
  end
end
