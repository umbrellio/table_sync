# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "table_sync/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.5.6"

  spec.name        = "table_sync"
  spec.version     = TableSync::VERSION
  spec.authors     = ["Umbrellio"]
  spec.email       = ["oss@umbrellio.biz"]
  spec.summary     = "DB Table synchronization between microservices " \
                     "based on Model's event system and RabbitMQ messaging"
  spec.description = "DB Table synchronization between microservices " \
                     "based on Model's event system and RabbitMQ messaging"
  spec.homepage    = "https://github.com/umbrellio/table_sync"
  spec.license     = "MIT"

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_runtime_dependency "memery"
  spec.add_runtime_dependency "rabbit_messaging", "~> 0.8.1"
  spec.add_runtime_dependency "rails"
  spec.add_runtime_dependency "self_data"

  spec.add_development_dependency "coveralls", "~> 0.8"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov", "~> 0.16"

  spec.add_development_dependency "activejob", ">= 6.0"
  spec.add_development_dependency "activerecord", ">= 6.0"
  spec.add_development_dependency "pg", "~> 0.18"
  spec.add_development_dependency "sequel"
  spec.add_development_dependency "timecop"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
end
