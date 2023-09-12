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
      :backtrace_filter, :ignorer, :substransactions_depth_threshold

    attr_reader :report_subtransactions

    def initialize
      @logger = nil
      @raise_exceptions = test_env?
      @send_notifications = false
      @backtrace_filter = ->(backtrace) { backtrace.take(5) }
      @ignorer = Isolator::Ignorer
      @substransactions_depth_threshold = nil
      @report_subtransactions = nil
    end

    alias_method :raise_exceptions?, :raise_exceptions
    alias_method :send_notifications?, :send_notifications

    def test_env?
      ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
    end

    def report_subtransactions=(report_type)
      if report_type == :log
        raise "Specify logger" unless logger

        @raise_exceptions = false
        @send_notifications = false
      elsif report_type == :exception
        @raise_exceptions = true
      elsif report_type == :notifier
        @send_notifications = true
      end

      @report_subtransactions = report_type
    end
  end
end
