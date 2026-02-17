# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "clickhouse_query_parser"
  spec.version       = "0.1.0"
  spec.authors       = ["User"]
  spec.email         = ["user@example.com"]

  spec.summary       = "A Ruby gem to parse ClickHouse SQL queries into a Hash and builder to convert Hash back to SQL."
  spec.description   = "A bidirectional ClickHouse SQL parser and builder."
  spec.homepage      = "https://github.com/example/clickhouse_query_parser"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files         = Dir.glob("lib/**/*") + ["README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rake", "~> 13.0"
end
