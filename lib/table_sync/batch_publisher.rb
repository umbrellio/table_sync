# frozen_string_literal: true

class TableSync::BatchPublisher < TableSync::BasePublisher
  def initialize(object_class, original_attributes_array, **options)
    @original_attributes_array = original_attributes_array.map do |hash|
      filter_safe_for_serialization(hash.deep_symbolize_keys)
    end

    @object_class             = object_class.constantize
    @confirm                  = options[:confirm] || true
    @routing_key              = options[:routing_key] || resolve_routing_key
    @push_original_attributes = options[:push_original_attributes] || false
    @headers                  = options[:headers]
    @event                    = options[:event] || :update
  end

  def publish
    enqueue_job
  end

  def publish_now
    return unless need_publish?
    Rabbit.publish(params)

    model_naming = TableSync.orm.model_naming(object_class)
    TableSync::Instrument.notify table: model_naming.table, schema: model_naming.schema,
                                 event: event,
                                 count: publishing_data[:attributes].size, direction: :publish
  end

  private

  attr_reader :original_attributes_array, :routing_key, :headers, :event

  def push_original_attributes?
    @push_original_attributes
  end

  def need_publish?
    (push_original_attributes? && original_attributes_array.present?) || objects.present?
  end

  memoize def objects
    needles.map { |needle| TableSync.orm.find(object_class, needle) }.compact
  end

  def job_callable
    TableSync.batch_publishing_job_class_callable
  end

  def job_callable_error_message
    "Can't publish, set TableSync.batch_publishing_job_class_callable"
  end

  def attrs_for_callables
    {}
  end

  def attrs_for_routing_key
    {}
  end

  def attrs_for_metadata
    {}
  end

  def params
    {
      **super,
      headers: headers,
    }
  end

  def needles
    original_attributes_array.map { |original_attributes| original_attributes.slice(*primary_keys) }
  end

  def publishing_data
    {
      **super,
      event: event,
      metadata: {},
    }
  end

  def attributes_for_sync
    return original_attributes_array if push_original_attributes?

    objects.map do |object|
      if attributes_for_sync_defined?
        object.attributes_for_sync
      else
        TableSync.orm.attributes(object)
      end
    end
  end

  def enqueue_job
    job_class.perform_later(
      object_class.name,
      original_attributes_array,
      enqueue_additional_options,
    )
  end

  def enqueue_additional_options
    { confirm: confirm?, push_original_attributes: push_original_attributes? }
  end
end
