# frozen_string_literal: true

module TableSync
  module Receiving
    require_relative "receiving/config"
    require_relative "receiving/config_decorator"
    require_relative "receiving/dsl"
    require_relative "receiving/handler"
    require_relative "receiving/model/active_record"
    require_relative "receiving/model/sequel"
  end
end
