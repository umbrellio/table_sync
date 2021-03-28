# frozen-string_literal: true

module TableSync::Setup
  class Base
    include Tainbox

    EVENTS            = %i[create update destroy].freeze
    INVALID_EVENTS    = Class.new(StandardError)
    INVALID_CONDITION = Class.new(StandardError)

    attribute :object_class
    attribute :debounce_time
    attribute :on,               default: []
    attribute :if_condition,     default: -> { Proc.new {} }
    attribute :unless_condition, default: -> { Proc.new {} }

    def initialize(attrs)
      super(attrs)

      self.on = Array.wrap(on).map(:to_sym)

      raise INVALID_EVENTS     unless valid_events?
      raise INVALID_CONDITIONS unless valid_conditions?
    end

    def register_callbacks
      applicable_events.each do |event|
        object_class.instance_exec(&define_after_commit_on(event))
      end
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

    def define_after_commit_on(event)
      raise NotImplementedError
    end

    def enqueue_message(original_attributes)
      TableSync::Publishing::Single.new(
        object_class: self.class.name,
        original_attributes: original_attributes,
        event: event,
        debounce_time: debounce_time,
      ).publish_later
    end
  end
end
