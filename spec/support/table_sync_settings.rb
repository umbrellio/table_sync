# frozen_string_literal: true

module TableSync::TestEnv
  module_function

  def setup!
    TableSync.orm                    = :active_record
    TableSync.raise_on_empty_message = nil

    TableSync.single_publishing_job_class_callable = -> { SingleTestJob }
    TableSync.batch_publishing_job_class_callable  = -> { BatchTestJob }
    TableSync.routing_key_callable                 = -> (klass, _attributes) { klass.tableize }
    TableSync.headers_callable                     = -> (klass, _attributes) { { klass: klass } }
    TableSync.notifier = nil
    TableSync.notify = nil
  end
end
