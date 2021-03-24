# frozen_string_literal: true

module TableSync::ORMAdapter
  module ActiveRecord
    module_function

    def model_naming(object)
      ::TableSync::NamingResolver::ActiveRecord.new(table_name: object.table_name)
    end

    def find(dataset, conditions)
      dataset.find_by(conditions)
    end

    def attributes(object)
      object.attributes
    end
  end
end
