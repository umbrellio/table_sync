# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "table_sync/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 3.1.0"

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

  spec.add_dependency "memery"
  spec.add_dependency "rabbit_messaging", ">= 1.7.0"
  spec.add_dependency "rails"
  spec.add_dependency "self_data"
end
