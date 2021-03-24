# frozen_string_literal: true

class TableSync::ORMAdapter::Sequel
    attr_reader :object, :object_class, :object_data

    def initialize(object_class, object_data)
      @object_class = object_class
      @object_data  = object_data

      validate!
    end

    def init
      @object = object_class.new(object_data)
    end

    def find
      @object = object_class.find(needle)
    end

    def needle
      object_data.slice(*primary_key_columns)
    end
    
    def validate!
      if (primary_key_columns - object_data.keys).any?
        raise NoPrimaryKeyError.new(object_class, object_data, primary_key_columns)
      end
    end

    def primary_key_columns
      Array.wrap(object_class.primary_key)
    end

    # ?
    def primary_key
      object.primary_key
    end

    def attributes
      object.values
    end

    def attributes_for_update
      if object.method_defined?(:attributes_for_sync)
        object.attributes_for_sync
      else
        attributes
      end
    end

    def attributes_for_destroy
      if object_class.method_defined?(:table_sync_destroy_attributes)
        object_class.table_sync_destroy_attributes(attributes)
      else
        primary_key
      end
    end
  end
end
