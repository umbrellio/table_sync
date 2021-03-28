# frozen_string_literal: true

class TableSync::Publishing::Single
  include Tainbox

  attribute :object_class
  attribute :original_attributes

  attribute :event,         default: :update
  attribute :debounce_time, default: 60

  def publish_later
    job.perform_later(job_attributes)
  end

  def publish_now
    # # Update request and object does not exist -> skip publishing
    # return if !object && !destroyed?

    TableSync::Publishing::Message::Single.new(attributes).publish
  end

  private

  # DEBOUNCE
  
  # JOB

  def job
    TableSync.single_publishing_job # || raise NoJobClassError.new("single")
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
