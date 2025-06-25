# frozen_string_literal: true

class TableSync::Publishing::Single
  include Memery

  attr_accessor :object_class,
                :original_attributes,
                :debounce_time,
                :custom_version,
                :event

  def initialize(attrs = {})
    attrs = attrs.with_indifferent_access

    self.object_class         = attrs[:object_class]
    self.original_attributes  = attrs[:original_attributes]
    self.debounce_time        = attrs[:debounce_time]
    self.custom_version       = attrs[:custom_version]
    self.event                = attrs.fetch(:event, :update)
  end

  # expect job to have perform_at method
  # debounce destroyed event
  # because otherwise update event could be sent after destroy
  def publish_later
    return if debounce.skip?

    job.perform_at(job_attributes)

    debounce.cache_next_sync_time
  end

  def publish_now
    message.publish unless message.empty?
  end

  memoize def message
    TableSync::Publishing::Message::Single.new(attributes)
  end

  memoize def debounce
    TableSync::Publishing::Helpers::Debounce.new(
      object_class:,
      needle: message.object.needle,
      debounce_time:,
      event:,
    )
  end

  private

  def attributes
    {
      object_class: object_class,
      original_attributes: original_attributes,
      debounce_time: debounce_time,
      custom_version: custom_version,
      event: event,
    }
  end

  # JOB

  def job
    if TableSync.single_publishing_job_class_callable
      TableSync.single_publishing_job_class_callable.call
    else
      raise TableSync::NoCallableError.new("single_publishing_job_class")
    end
  end

  def job_attributes
    attributes.merge(
      original_attributes: serialized_original_attributes,
      perform_at: debounce.next_sync_time,
    )
  end

  def serialized_original_attributes
    TableSync::Publishing::Helpers::Attributes
      .new(original_attributes)
      .serialize
  end
end
