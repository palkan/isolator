# frozen_string_literal: true

module Isolator
  # Isolator configuration:
  #
  # - `raise_exceptions` - whether to raise an exception in case of offense;
  #   defaults to true in test env and false otherwise.
  #   NOTE: env is infered from RACK_ENV and RAILS_ENV.
  #
  # - `logger` - logger instance (nil by default)
  #
  # - `send_notifications` - whether to send notifications (through uniform_notifier);
  #   defauls to false
  class Configuration
    attr_accessor :raise_exceptions, :logger, :send_notifications

    def initialize
      @logger = nil
      @raise_exceptions = test_env?
      @send_notifications = false
    end

    alias raise_exceptions? raise_exceptions
    alias send_notifications? send_notifications

    def test_env?
      ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test"
    end
  end
end
