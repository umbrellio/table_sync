# frozen_string_literal: true

module TableSync
  module Publishing
    require_relative "publishing/data/objects"
    require_relative "publishing/data/raw"

    require_relative "publishing/helpers/attributes"
    require_relative "publishing/helpers/debounce"
    require_relative "publishing/helpers/objects"

    require_relative "publishing/params/base"
    require_relative "publishing/params/batch"
    require_relative "publishing/params/raw"
    require_relative "publishing/params/single"

    require_relative "publishing/message/base"
    require_relative "publishing/message/batch"
    require_relative "publishing/message/raw"
    require_relative "publishing/message/single"

    require_relative "publishing/batch"
    require_relative "publishing/raw"
    require_relative "publishing/single"
  end
end
