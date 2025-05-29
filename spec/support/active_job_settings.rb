# frozen_string_literal: true

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(File::NULL)

SingleTestJob = Class.new(ActiveJob::Base)
BatchTestJob  = Class.new(ActiveJob::Base)
