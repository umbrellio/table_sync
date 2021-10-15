# frozen_string_literal: true

module TableSync::Publishing::Helpers
  class Objects
    attr_reader :object_class, :original_attributes, :event

    def initialize(object_class:, original_attributes:, event:)
      @event               = TableSync::Event.new(event)
      @object_class        = object_class.constantize
      @original_attributes = Array.wrap(original_attributes)
    end

    def construct_list
      if event.destroy?
        init_objects
      else
        without_empty_objects(find_objects)
      end
    end

    private

    def without_empty_objects(objects)
      objects.reject(&:empty?)
    end

    def init_objects
      original_attributes.map do |attrs|
        TableSync.publishing_adapter.new(object_class, attrs).init
      end
    end

    def find_objects
      original_attributes.map do |attrs|
        TableSync.publishing_adapter.new(object_class, attrs).find
      end
    end
  end
end
