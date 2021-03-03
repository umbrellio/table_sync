# frozen_string_literal: true

TableSync.orm = :active_record
TableSync.publishing_job_class_callable = -> { TestJob }
