# frozen_string_literal: true

module TableSync::ORMAdapter
  class Base
    attr_reader :object, :object_class, :object_data

    # :nocov:
    def self.model_naming
      raise NotImplementedError
    end
    # :nocov:

    def initialize(object_class, object_data)
      @object_class = object_class
      @object_data  = object_data.symbolize_keys

      validate!
    end

    # VALIDATE

    def validate!
      if (primary_key_columns - object_data.keys).any?
        raise TableSync::NoPrimaryKeyError.new(object_class, object_data, primary_key_columns)
      end
    end

    # FIND OR INIT OBJECT

    def init
      self
    end

    def find
      self
    end

    def needle
      object_data.slice(*primary_key_columns)
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
      if object.respond_to?(:attributes_for_destroy)
        object.attributes_for_destroy
      else
        needle
      end
    end

    def attributes_for_routing_key
      if object.respond_to?(:attributes_for_routing_key)
        object.attributes_for_routing_key
      else
        attributes
      end
    end

    def attributes_for_headers
      if object.respond_to?(:attributes_for_headers)
        object.attributes_for_headers
      else
        attributes
      end
    end

    def primary_key_columns
      Array.wrap(object_class.primary_key).map(&:to_sym)
    end

    # MISC

    def empty?
      object.nil?
    end

    # NOT IMPLEMENTED

    # :nocov:
    def attributes
      raise NotImplementedError
    end
    # :nocov:
  end
end
