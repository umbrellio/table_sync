# frozen_string_literal: true

class TableSync::Publishing::Publisher
  include Tainbox

  attribute :klass
  attribute :attrs
  attribute :state
  attribute :routing_key
  attribute :headers

  attribute :raw, default: false

  # how necessary is serialization check?
  def publish
    job.perform_later(attributes)
  end

  def publish_now
    message.publish
  end

  private

  # MESSAGE

  def message
    raw ? raw_message : batch_message
  end

  def batch_message
    TableSync::Publishing::Message::Batch.new(**message_params)
  end

  def raw_message
    TableSync::Publishing::Message::Raw.new(**message_params)
  end

  def message_params
    attributes.slice(
      :klass, :attrs, :state, :routing_key, :headers
    )
  end

  # JOB

  def job
    job_callable ? job_callable.call : raise job_callable_error_message
  end

  def job_callable
    TableSync.batch_publishing_job_class_callable
  end

  def job_callable_error_message
    "Can't publish, set TableSync.batch_publishing_job_class_callable"
  end
end

# Насколько нужно проверять сриализацию? Никто не пихает туда сложные объекты.

# Не надо конфёрм.