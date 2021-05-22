# frozen_string_literal: true

module TableSync::ORMAdapter
  class Base
    attr_reader :object, :object_class, :object_data

    def initialize(object_class, object_data)
      @object_class = object_class
      @object_data  = object_data

      validate!
    end

    # VALIDATE
    
    def validate!
      if (primary_key_columns - object_data.keys).any?
        raise NoPrimaryKeyError.new(object_class, object_data, primary_key_columns)
      end
    end

    # FIND OR INIT OBJECT

    def init
      @object = object_class.new(object_data.except(*primary_key_columns))

      needle.each do |column, value|
        @object.send("#{column}=", value)
      end

      self
    end

    def find
      # @object = object_class.find(needle)

      self
    end

    def needle
      object_data.slice(*primary_key_columns)
    end

    def primary_key_columns
      Array.wrap(object_class.primary_key).map(&:to_sym) # temp!
    end

    # ATTRIBUTES

    def attributes_for_update
      if object.respond_to?(:attributes_for_sync)
        object.attributes_for_sync
      else
        attributes
      end
    end

    def attributes_for_destroy
      if object_class.respond_to?(:table_sync_destroy_attributes)
        object_class.table_sync_destroy_attributes(attributes)
      else
        primary_key
      end
    end

    # MISC

    def empty?
      object.nil?
    end

    # NOT IMPLEMENTED

    def primary_key
      raise NotImplementedError
    end

    def attributes
      raise NotImplementedError
    end
  end
end
