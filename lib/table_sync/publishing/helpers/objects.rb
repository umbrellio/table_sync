# frozen_string_literal: true

module TableSync::Publishing::Helpers
  class Objects
    attr_reader :object_class, :original_attributes, :event

    def initialize(object_class:, original_attributes:, event:)
      self.event               = event
      self.object_class        = object_class.constantize
      self.original_attributes = Array.wrap(original_attributes)
    end

    def construct_list
      destruction? ? init_objects : find_objects
    end

    private

    def init_objects
      original_attributes.each do |attrs|
        TableSync.publishing_adapter.new(object_class, attrs).init
      end
    end

    def find_objects
      original_attributes.each do |attrs|
        TableSync.publishing_adapter.new(object_class, attrs).find
      end
    end

    def destruction?
      event == :destroy
    end
  end
end
