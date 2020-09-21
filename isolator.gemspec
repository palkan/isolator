# frozen_string_literal: true

require_relative "lib/isolator/version"

Gem::Specification.new do |spec|
  spec.name = "isolator"
  spec.version = Isolator::VERSION
  spec.authors = ["Vladimir Dementyev"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Detect non-atomic interactions within DB transactions"
  spec.description = "Detect non-atomic interactions within DB transactions"
  spec.homepage = "https://github.com/palkan/isolator"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.5.0"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/isolator/issues",
    "changelog_uri" => "https://github.com/palkan/isolator/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/isolator",
    "homepage_uri" => "http://github.com/palkan/isolator",
    "source_code_uri" => "http://github.com/palkan/isolator"
  }

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sniffer", ">= 0.3.1"

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", ">= 3.0"
  spec.add_development_dependency "minitest", "~> 5.10.0"

  spec.add_development_dependency "sidekiq", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 3.1"
  spec.add_development_dependency "test_after_commit", "~> 1.1"
  spec.add_development_dependency "resque"
  spec.add_development_dependency "fakeredis"
  spec.add_development_dependency "resque-scheduler"
  spec.add_development_dependency "sucker_punch"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "after_commit_everywhere"
  spec.add_development_dependency "uniform_notifier"
end
