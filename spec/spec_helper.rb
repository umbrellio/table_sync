# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = "coverage/lcov.info"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter,
])

SimpleCov.start { add_filter "spec" }

require "bundler/setup"
require "pry"
require "ostruct"

require "active_job" # NOTE: runtime dependency
require "sequel" # NOTE: runtime dependency
require "timecop" # NOTE: runtime dependency
require "rabbit_messaging" # NOTE: runtime dependency
require "rabbit/test_helpers" # NOTE: from rabbit_messaging
require "table_sync"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |file| require file }

TableSync::TestEnv.setup!

RSpec.configure do |config|
  config.include Rabbit::TestHelpers

  Kernel.srand(config.seed)
  config.order = :random

  config.disable_monkey_patching!
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.default_formatter = "doc" if config.files_to_run.one?
  config.expose_dsl_globally = true
  config.profile_examples = 10

  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.after { TableSync::TestEnv.setup! }
end
