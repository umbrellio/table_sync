# frozen_string_literal: true

class TableSync::Publishing::Batch
  include Tainbox

  attribute :object_class
  attribute :original_attributes

  attribute :routing_key
  attribute :headers

  attribute :event, default: :update

  def publish_later
    job.perform_later(job_attributes)
  end

  def publish_now
    TableSync::Publishing::Message::Batch.new(attributes).publish
  end

  private

  # JOB

  def job
    if TableSync.batch_publishing_job_class_callable
      TableSync.batch_publishing_job_class_callable.call
    else
      raise TableSync::NoJobClassError.new("batch")
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
