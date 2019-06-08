# frozen_string_literal: true

class TableSync::Publisher < TableSync::BasePublisher
  DEBOUNCE_TIME = 1.minute

  # 'original_attributes' are not published, they are used to resolve the routing key
  def initialize(object_class, original_attributes, destroyed: nil, confirm: true, state: :updated)
    @object_class = object_class.constantize
    @original_attributes = filter_safe_for_serialization(original_attributes.deep_symbolize_keys)
    @confirm = confirm

    if destroyed.nil?
      @state = validate_state(state)
    else
      # TODO Legacy job support, remove
      @state = destroyed ? :destroyed : :updated
    end
  end

  def publish
    return enqueue_job if destroyed?

    sync_time = Rails.cache.read(cache_key) || current_time - DEBOUNCE_TIME - 1.second
    return if sync_time > current_time

    next_sync_time = sync_time + DEBOUNCE_TIME
    next_sync_time <= current_time ? enqueue_job : enqueue_job(next_sync_time)
  end

  def publish_now
    # Update request and object does not exist -> skip publishing
    return if !object && !destroyed?

    Rabbit.publish(params)
  end

  private

  attr_reader :original_attributes
  attr_reader :state

  def attrs_for_callables
    original_attributes
  end

  def attrs_for_routing_key
    return object.attrs_for_routing_key if attrs_for_routing_key_defined?
    attrs_for_callables
  end

  def attrs_for_metadata
    return object.attrs_for_metadata if attrs_for_metadata_defined?
    attrs_for_callables
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
      event: (destroyed? ? :destroy : :update),
      metadata: { created: created? },
    }
  end

  def attributes_for_sync
    if destroyed?
      if object_class.respond_to?(:table_sync_destroy_attributes)
        object_class.table_sync_destroy_attributes(original_attributes)
      else
        needle
      end
    elsif attributes_for_sync_defined?
      object.attributes_for_sync
    else
      TableSync.orm.attributes(object)
    end
  end

  memoize def object
    TableSync.orm.find(object_class, needle)
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

  def validate_state(state)
    if %i[created updated destroyed].include?(state&.to_sym)
      state.to_sym
    else
      raise "Unknown state: #{state.inspect}"
    end
  end
end
