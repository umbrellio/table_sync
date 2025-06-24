# frozen_string_literal: true

class TableSync::Publishing::Batch
  attr_accessor :object_class,
                :original_attributes,
                :custom_version,
                :routing_key,
                :headers,
                :event

  def initialize(attrs = {})
    attrs = attrs.deep_symbolize_keys

    self.object_class         = attrs[:object_class]
    self.original_attributes  = attrs[:original_attributes]
    self.custom_version       = attrs[:custom_version]
    self.routing_key          = attrs[:routing_key]
    self.headers              = attrs[:headers]
    self.event                = attrs.fetch(:event, :update).to_sym

    validate_required_attributes!
  end

  def publish_later
    job.perform_later(job_attributes)
  end

  def publish_now
    message.publish
  end

  def message
    TableSync::Publishing::Message::Batch.new(attributes)
  end

  alias_method :publish_async, :publish_later

  private

  def validate_required_attributes!
    missing = []
    missing << :object_class if object_class.nil?
    missing << :original_attributes if original_attributes.nil?

    unless missing.empty?
      raise ArgumentError, "Some of required attributes is not provided: #{missing.inspect}"
    end
  end

  def attributes
    {
      object_class: object_class,
      original_attributes: original_attributes,
      custom_version: custom_version,
      routing_key: routing_key,
      headers: headers,
      event: event,
    }
  end

  # JOB

  def job
    if TableSync.batch_publishing_job_class_callable
      TableSync.batch_publishing_job_class_callable.call
    else
      raise TableSync::NoCallableError.new("batch_publishing_job_class")
    end
  end

  def job_attributes
    attributes.merge(
      original_attributes: serialized_original_attributes,
    )
  end

  def serialized_original_attributes
    original_attributes.map do |set_of_attributes|
      TableSync::Publishing::Helpers::Attributes
        .new(set_of_attributes)
        .serialize
    end
  end
end
