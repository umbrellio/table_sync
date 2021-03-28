# frozen_string_literal: true

module TableSync::ORMAdapter
  class ActiveRecord < Base
    def primary_key
      object.pk_hash
    end

    def attributes
      object.attributes
    end
  end
end


# module TableSync::ORMAdapter
#   module ActiveRecord
#     module_function

#     def model_naming(object)
#       ::TableSync::NamingResolver::ActiveRecord.new(table_name: object.table_name)
#     end

#     def find(dataset, conditions)
#       dataset.find_by(conditions)
#     end

#     def attributes(object)
#       object.attributes
#     end
#   end
# end


# frozen_string_literal: true

# class TableSync::ORMAdapter::Sequel
#     attr_reader :object, :object_class, :object_data

#     def initialize(object_class, object_data)
#       @object_class = object_class
#       @object_data  = object_data

#       validate!
#     end

#     def init
#       @object = object_class.new(object_data)
#     end

#     def find
#       @object = object_class.find(needle)
#     end

#     def needle
#       object_data.slice(*primary_key_columns)
#     end
    
#     def validate!
#       if (primary_key_columns - object_data.keys).any?
#         raise NoPrimaryKeyError.new(object_class, object_data, primary_key_columns)
#       end
#     end

#     def primary_key_columns
#       Array.wrap(object_class.primary_key)
#     end

#     def primary_key
#       object.pk_hash
#     end

#     def attributes
#       object.values
#     end

#     def attributes_for_update
#       if object.respond_to?(:attributes_for_sync)
#         object.attributes_for_sync
#       else
#         attributes
#       end
#     end

#     def attributes_for_destroy
#       if object_class.respond_to?(:table_sync_destroy_attributes)
#         object_class.table_sync_destroy_attributes(attributes)
#       else
#         primary_key
#       end
#     end
#   end
# end
