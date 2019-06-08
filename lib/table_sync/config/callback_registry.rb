# frozen_string_literal: true

class TableSync::Config::CallbackRegistry
  CALLBACK_KINDS = %i[after_commit before_commit].freeze
  EVENTS = %i[create update destroy].freeze

  InvalidCallbackKindError = Class.new(ArgumentError)
  InvalidEventError = Class.new(ArgumentError)

  def initialize
    @callbacks = CALLBACK_KINDS.map { |event| [event, make_event_hash] }.to_h
  end

  def register_callback(callback, kind:, event:)
    validate_callback_kind!(kind)
    validate_event!(event)

    callbacks.fetch(kind)[event] << callback
  end

  def get_callbacks(kind:, event:)
    validate_callback_kind!(kind)
    validate_event!(event)

    callbacks.fetch(kind).fetch(event, [])
  end

  private

  attr_reader :callbacks

  def make_event_hash
    Hash.new { |hsh, key| hsh[key] = [] }
  end

  def validate_callback_kind!(kind)
    unless CALLBACK_KINDS.include?(kind)
      raise(
        InvalidCallbackKindError,
        "Invalid callback kind: #{kind.inspect}. Valid kinds are #{CALLBACK_KINDS.inspect}",
      )
    end
  end

  def validate_event!(event)
    unless EVENTS.include?(event)
      raise(
        InvalidEventError,
        "Invalid event: #{event.inspect}. Valid events are #{EVENTS.inspect}",
      )
    end
  end
end
