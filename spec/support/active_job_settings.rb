# frozen_string_literal: true

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new("/dev/null")
