# frozen_string_literal: true

# check if works!
module TableSync::Publishing::Data
	class Raw
  	attr_reader :object_class, :attributes_for_sync, :event

    def initialize(object_class:, attributes_for_sync:, event:)
      @object_class 			 = object_class
      @attributes_for_sync = attributes_for_sync
      @event        			 = event
    end

    def construct
      {
        model:      object_class,# model,
        attributes: attributes_for_sync,
        version:    Time.current.to_f,#version,
        event:      event,
        metadata:   {}, #metadata,
      }
    end
	end
end
