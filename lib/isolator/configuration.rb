# frozen_string_literal: true

module Isolator
  # Isolator configuration:
  #
  # - `raise_exceptions` - whether to raise an exception in case of offense;
  #   defaults to true in test env and false otherwise.
  #   NOTE: env is inferred from RACK_ENV and RAILS_ENV.
  #
  # - `logger` - logger instance (nil by default)
  #
  # - `send_notifications` - whether to send notifications (through uniform_notifier);
  #   defaults to false
  #
  # - `backtrace_filter` - define a custom backtrace filtering (provide a callable)
  #
  # - `ignorer` - define a custom ignorer (must implement .prepare)
  #
  class Configuration
    attr_accessor :raise_exceptions, :logger, :send_notifications,
      :backtrace_filter, :ignorer

    def initialize
      @logger = nil
      @raise_exceptions = test_env?
      @send_notifications = false
      @backtrace_filter = ->(backtrace) { backtrace.take(5) }
      @ignorer = Isolator::Ignorer
    end

    alias raise_exceptions? raise_exceptions
    alias send_notifications? send_notifications

    def test_env?
      ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
    end
  end
end
