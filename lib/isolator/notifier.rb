# frozen_string_literal: true

module Isolator
  # Wrapper over different notifications methods (exceptions, logging, uniform notifier)
  class Notifier
    attr_reader :exception, :backtrace

    def initialize(exception, backtrace = caller)
      @exception = exception
      @backtrace = backtrace
    end

    def call
      log_exception
      send_notifications if send_notifications?
      raise(exception.class, exception.message, filtered_backtrace) if raise_exceptions?
    end

    private

    def raise_exceptions?
      Isolator.config.raise_exceptions?
    end

    def send_notifications?
      Isolator.config.send_notifications?
    end

    def log_exception
      return unless Isolator.config.logger

      offense_line = filtered_backtrace.first

      msg = "[ISOLATOR EXCEPTION]\n" \
            "#{exception.message}"

      msg += "\n  ↳ #{offense_line}" if offense_line

      Isolator.config.logger.warn(msg)
    end

    def send_notifications
      return unless uniform_notifier_loaded?

      ::UniformNotifier.active_notifiers.each do |notifier|
        notifier.out_of_channel_notify exception.message
      end
    end

    def filtered_backtrace
      backtrace.reject { |line| line =~ /\/(gems|ruby)/ }.take_while { |line| line !~ /ruby/ }
    end

    def uniform_notifier_loaded?
      return true if defined?(::UniformNotifier)

      warn(
        "Please, install Isolator version 0.4.0 to use" \
        " 'uniform_notifier' to send notifications.\n"
      )
      false
    end
  end
end
