# frozen_string_literal: true

module TableSync::ORMAdapter
  class ActiveRecord < Base
    def self.model_naming(object_class)
      TableSync::NamingResolver::ActiveRecord.new(table_name: object_class.table_name)
    end

    def find
      @object = object_class.find_by(needle)

      super
    end

    def init
      @object = object_class.new(object_data)

      super
    end

    def attributes
      object.attributes.symbolize_keys
    end
  end
end
