# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "active_support"
require "uniform_notifier"

require "sidekiq"
require "sidekiq/testing"

Sidekiq::Testing.fake!

require "resque"
require "resque-scheduler"
require "sucker_punch"

require "net/http"
require "uri"

require "vcr"

begin
  require "debug" unless ENV["CI"] == "true"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

require "isolator"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.filter_run focus: true
  # TODO: remove first condition once 8.0 is released
  if (Rails::VERSION::MAJOR >= 7 && Rails::VERSION::MINOR >= 2) || (Rails::VERSION::MAJOR >= 8)
    config.filter_run_excluding :rails_pre_8
  else
    config.filter_run_excluding :rails8
  end
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.define_derived_metadata(file_path: %r{/spec/integrations/}) do |metadata|
    metadata[:type] = :integration
  end

  config.include IntegrationHelpers, type: :integration

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after do
    Isolator.remove_instance_variable(:@config) if
     Isolator.instance_variable_defined?(:@config)

    Isolator.clear_transactions!
  end
end
