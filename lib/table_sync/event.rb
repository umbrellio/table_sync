# frozen_string_literal: true

class TableSync::Event
  attr_reader :event

  UPSERT_EVENTS          = %i[create update].freeze
  VALID_RESOLVED_EVENTS  = %i[update destroy].freeze
  VALID_RAW_EVENTS       = %i[create update destroy].freeze

  def initialize(event)
    @event = event

    validate!
  end

  def validate!
    raise TableSync::EventError.new(event) unless event.in?(VALID_RAW_EVENTS)
  end

  def resolve
    destroy? ? :destroy : :update
  end

  def metadata
    { created: event == :create }
  end

  def destroy?
    event == :destroy
  end

  def upsert?
    event.in?(UPSERT_EVENTS)
  end
end
