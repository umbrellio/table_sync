# frozen_string_literal: true

class TableSync::Publishing::Single
  include Tainbox
  include Memery

  attribute :object_class
  attribute :original_attributes

  attribute :event,         default: :update
  attribute :debounce_time, default: 60

  def publish_later
    job.perform_later(job_attributes)
  end

  def publish_now
    message.publish unless message.empty? && upsert_event?
  end

  memoize def message
    TableSync::Publishing::Message::Single.new(attributes)
  end

  private

  def upsert_event?
    event.in?(%i[update create])
  end

  # DEBOUNCE

  # TO DO
  
  # JOB

  def job
    if TableSync.single_publishing_job_class_callable
      TableSync.single_publishing_job_class_callable&.call
    else
      raise TableSync::NoJobClassError.new("single")
    end
  end

  def job_attributes
    attributes.merge(
      original_attributes: serialized_original_attributes,
    )
  end

  def serialized_original_attributes
    TableSync::Publishing::Helpers::Attributes
      .new(original_attributes)
      .serialize
  end
end
