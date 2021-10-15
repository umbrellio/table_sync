# frozen-string_literal: true

module TableSync::Setup
  class Base
    include Tainbox

    EVENTS            = %i[create update destroy].freeze
    INVALID_EVENT     = Class.new(StandardError)
    INVALID_CONDITION = Class.new(StandardError)

    attribute :object_class
    attribute :debounce_time
    attribute :on
    attribute :if_condition
    attribute :unless_condition

    def initialize(attrs)
      super(attrs)

      self.on = Array.wrap(on).map(&:to_sym)

      self.if_condition     ||= proc { true }
      self.unless_condition ||= proc { false }

      raise INVALID_EVENTS    unless valid_events?
      raise INVALID_CONDITION unless valid_conditions?
    end

    def register_callbacks
      applicable_events.each { |event| define_after_commit(event) }
    end

    private

    # VALIDATION

    def valid_events?
      on.all? { |event| event.in?(EVENTS) }
    end

    def valid_conditions?
      if_condition.is_a?(Proc) && unless_condition.is_a?(Proc)
    end

    # EVENTS

    def applicable_events
      on.presence || EVENTS
    end

    # CREATING HOOKS

    # :nocov:
    def define_after_commit(event)
      raise NotImplementedError
    end
    # :nocov:

    def options_exposed_for_block
      {
        if: if_condition,
        unless: unless_condition,
        debounce_time: debounce_time,
      }
    end
  end
end
