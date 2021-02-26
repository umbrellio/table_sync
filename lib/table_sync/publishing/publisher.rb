# frozen_string_literal: true

class TableSync::Publishing::Publisher < TableSync::Publishing::BasePublisher
  DEBOUNCE_TIME = 1.minute

  # 'original_attributes' are not published, they are used to resolve the routing key
  def initialize(object_class, original_attributes, **opts)
    @object_class = object_class.constantize
    @original_attributes = filter_safe_for_serialization(original_attributes.deep_symbolize_keys)
    @confirm = opts.fetch(:confirm, true)
    @debounce_time = opts[:debounce_time]&.seconds || DEBOUNCE_TIME
    @state = opts.fetch(:state, :updated).to_sym
    validate_state
  end

  def publish
    return enqueue_job if destroyed? || debounce_time.zero?

    sync_time = Rails.cache.read(cache_key) || current_time - debounce_time - 1.second
    return if sync_time > current_time

    next_sync_time = sync_time + debounce_time
    next_sync_time <= current_time ? enqueue_job : enqueue_job(next_sync_time)
  end

  def publish_now
    # Update request and object does not exist -> skip publishing
    return if !object && !destroyed?

    Rabbit.publish(params)
    model_naming = TableSync.publishing_adapter.model_naming(object_class)
    TableSync::Instrument.notify table: model_naming.table, schema: model_naming.schema,
                                 event: event, direction: :publish
  end

  private

  attr_reader :original_attributes
  attr_reader :state
  attr_reader :debounce_time

  def attrs_for_callables
    attributes_for_sync
  end

  def attrs_for_routing_key
    if object.respond_to?(:attrs_for_routing_key)
      object.attrs_for_routing_key
    else
      attrs_for_callables
    end
  end

  def attrs_for_metadata
    if object.respond_to?(:attrs_for_metadata)
      object.attrs_for_metadata
    else
      attrs_for_callables
    end
  end

  def job_callable
    TableSync.publishing_job_class_callable
  end

  def job_callable_error_message
    "Can't publish, set TableSync.publishing_job_class_callable"
  end

  def enqueue_job(perform_at = current_time)
    job = job_class.set(wait_until: perform_at)
    job.perform_later(object_class.name, original_attributes, state: state.to_s, confirm: confirm?)
    Rails.cache.write(cache_key, perform_at)
  end

  def routing_key
    resolve_routing_key
  end

  def publishing_data
    {
      **super,
      event: event,
      metadata: { created: created? },
    }
  end

  memoize def attributes_for_sync
    if destroyed?
      if object_class.respond_to?(:table_sync_destroy_attributes)
        object_class.table_sync_destroy_attributes(original_attributes)
      else
        original_attributes
      end
    elsif attributes_for_sync_defined?
      object.attributes_for_sync
    else
      TableSync.publishing_adapter.attributes(object)
    end
  end

  memoize def object
    TableSync.publishing_adapter.find(object_class, needle)
  end

  def event
    destroyed? ? :destroy : :update
  end

  def needle
    original_attributes.slice(*primary_keys)
  end

  def cache_key
    "#{object_class}/#{needle}_table_sync_time".delete(" ")
  end

  def destroyed?
    state == :destroyed
  end

  def created?
    state == :created
  end

  def validate_state
    raise "Unknown state: #{state.inspect}" unless %i[created updated destroyed].include?(state)
  end
end
