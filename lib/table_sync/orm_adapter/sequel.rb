# frozen_string_literal: true

module TableSync::ORMAdapter
  class Sequel < Base
    def attributes
      object.values
    end

    def init
      @object = object_class.new(object_data.except(*primary_key_columns))

      @object.set_fields(needle, needle.keys)

      super
    end

    def find
      @object = object_class.find(needle)

      super
    end

    def self.model_naming(object_class)
      TableSync::NamingResolver::Sequel.new(
        table_name: object_class.table_name, db: object_class.db,
      )
    end
  end
end
