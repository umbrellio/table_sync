# frozen_string_literal: true

class TableSync::Publishing::Data::Objects
  attr_reader :objects, :event

  def initialize(objects:, event:)
    @objects = objects
    @event   = event
  end

  def construct
    {
      model:      model,
      attributes: attributes_for_sync,
      version:    version,
      event:      event,
      metadata:   metadata,
    }
  end

  private

  def model
    if object_class.method_defined?(:table_sync_model_name)
      object_class.table_sync_model_name
    else
      object_class.name
    end
  end

  def version
    Time.current.to_f
  end

  def metadata
    { created: event == :create } # remove? who needs this?
  end

  def object_class
    objects.first.class
  end

  def attributes_for_sync
    objects.map do |object|
      if destruction?
        object.attributes_for_destroy
      else
        object.attributes_for_update
      end
    end
  end

  def destruction?
    event == :destroy
  end
end
