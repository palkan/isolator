# frozen_string_literal: true

module Isolator
  class Notifier
    attr_reader :object, :backtrace

    def initialize(object, backtrace = [])
      @object = object
      @backtrace = backtrace
    end

    def call
      raise(exception_klass, exception_message, filtered_backtrace) if raise_exceptions?
      send_notifications if send_notifications?
    end

    private

    def raise_exceptions?
      Isolator.config.raise_exceptions
    end

    def send_notifications?
      Isolator.config.send_notifications
    end

    def exception_klass
      @exception ||= if object.respond_to?(:isolator_exception)
        object.isolator_exception
      else
        Isolator::UnsafeOperationError
      end
    end

    def send_notifications
      UniformNotifier.active_notifiers.each do |notifier|
        notifier.out_of_channel_notify exception_message
      end
    end

    def exception_message
      @exception_message ||= exception_klass.exception.message
    end

    def filtered_backtrace
      backtrace.reject { |line| line =~ /gems/ }.take_while { |line| line !~ /ruby/ }
    end
  end
end
