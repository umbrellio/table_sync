# frozen_string_literal: true

module TableSync::NamingResolver
  class ActiveRecord
    def initialize(table_name:)
      @table_name = table_name
    end

    def table
      meta_data.last
    end

    def schema
      meta_data.size > 1 ? meta_data[-2] : "public"
    end

    private

    attr_reader :table_name

    def meta_data
      table_name.to_s.split "."
    end
  end
end
