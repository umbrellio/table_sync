# frozen_string_literal: true

class TableSync::Publishing::Single
  include Tainbox
  include Memery

  attribute :object_class
  attribute :original_attributes
  attribute :debounce_time

  attribute :event, Symbol, default: :update

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
      object_class: object_class,
      needle: message.object.needle,
      debounce_time: debounce_time,
      event: event,
    )
  end

  private

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
