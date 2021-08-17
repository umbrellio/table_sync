# frozen_string_literal: true

module TableSync::ORMAdapter
  class ActiveRecord < Base
    def primary_key
      object_class.primary_key
    end

    def find
      @object = object_class.find_by(needle)

      super
    end

    def attributes
      object.attributes.symbolize_keys
    end

    def self.model_naming(object_class)
      TableSync::NamingResolver::ActiveRecord.new(table_name: object_class.table_name)
    end
  end
end
