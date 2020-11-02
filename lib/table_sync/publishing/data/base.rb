# frozen_string_literal: true

class TableSync::Publishing::Data::Base
  include Tainbox

  attribute :state, default: :updated

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

  # MISC

  def model
    klass.try(:table_sync_model_name) || klass.name
  end

  def version
    Time.current.to_f
  end

  def metadata
    {}
  end

  # STATE, EVENT

  def destroyed?
    state == :destroyed
  end

  def created?
    state == :created
  end

  def event
    destroyed? ? :destroy : :update
  end

  # NOT IMPLEMENTED

  def klass
    raise NotImplementedError
  end

  def attributes_for_sync
    raise NotImplementedError
  end
end

# def validate_state
#   raise "Unknown state: #{state.inspect}" unless %i[created updated destroyed].include?(state)
# end