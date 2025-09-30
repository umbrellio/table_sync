# frozen_string_literal: true

class TableSync::Utils::Schema
  module Builder
    class ActiveRecord
      class << self
        # TODO: make schema builder for Active Record
        def build(_active_record_schema)
          TableSync::Utils::Schema.new({})
        end
      end
    end
  end
end
