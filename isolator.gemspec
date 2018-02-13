lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "isolator/version"

Gem::Specification.new do |spec|
  spec.name          = "isolator"
  spec.version       = Isolator::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "Detect non-atomic interactions within DB transactions"
  spec.description   = "Detect non-atomic interactions within DB transactions"
  spec.homepage      = "https://github.com/palkan/isolator"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.3.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency 'uniform_notifier', "~> 1.11"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.51"
  spec.add_development_dependency "rubocop-md", "~> 0.2"

  spec.add_development_dependency "httpclient", "~> 2.8.3"
  spec.add_development_dependency "http", "~> 3.0.0"
  spec.add_development_dependency "patron", "~> 0.10.0"
  spec.add_development_dependency "ethon", "~> 0.11.0"
  spec.add_development_dependency "typhoeus", "~> 1.3.0"

  spec.add_development_dependency "sidekiq", "~> 5.0"
  spec.add_development_dependency "delayed_job_active_record"
end
