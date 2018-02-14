# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "active_support"
require "uniform_notifier"

require "sidekiq"
require "net/http"
require "uri"

begin
  require "pry-byebug"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

require "isolator"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after(:each) do
    Isolator.remove_instance_variable(:@config) if
     Isolator.instance_variable_defined?(:@config)

    Isolator.clear_transactions!
  end
end
