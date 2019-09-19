# frozen_string_literal: true

module TableSync::NamingResolver
  class Sequel
    def initialize(table_name:, db:)
      @table_name = table_name
      @db = db
    end

    def table
      table_name.is_a?(::Sequel::SQL::QualifiedIdentifier) ? table_name.column : table_name
    end

    def schema
      return table_name.table if table_name.is_a?(::Sequel::SQL::QualifiedIdentifier)
      db.get(Sequel.function("current_schema")) rescue "public"
    end

    private

    attr_reader :table_name, :db
  end
end
