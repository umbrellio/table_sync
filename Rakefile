# frozen_string_literal: true

require "bundler/gem_tasks"
require "bundler/audit/task"
require "rspec/core/rake_task"
require "rubocop"
require "rubocop-rspec"
require "rubocop-performance"
require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop) do |t|
  config_path = File.expand_path(File.join(".rubocop.yml"), __dir__)

  t.options = ["--config", config_path]
  t.requires << "rubocop-rspec"
  t.requires << "rubocop-performance"
end

RSpec::Core::RakeTask.new(:rspec)
Bundler::Audit::Task.new

task default: :rspec
