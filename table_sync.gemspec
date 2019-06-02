# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "table_sync/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.3.8"

  spec.name        = "table_sync"
  spec.version     = TableSync::VERSION
  spec.authors     = ["Umbrellio"]
  spec.email       = ["oss@umbrellio.biz"]
  spec.summary     = "Coming soon"
  spec.description = "Coming soon"
  spec.homepage    = "https://github.com/umbrellio/table_sync"
  spec.license     = "MIT"

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_development_dependency "coveralls", "~> 0.8"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rubocop-config-umbrellio", "~> 0.70"
  spec.add_development_dependency "simplecov", "~> 0.16"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
end
