# frozen_string_literal: true

module Isolator
  module Adapters
    # Used as a "template" for adapters
    module Base
      attr_accessor :exception_class, :exception_message, :details_message

      def disable!
        @disabled = true
      end

      def enable!
        @disabled = false
      end

      def enabled?
        !disabled?
      end

      def disabled?
        @disabled == true
      end

      def notify(backtrace, obj, *args)
        return unless notify?(*args)
        Isolator.notify(exception: build_exception(obj, args), backtrace: backtrace)
      end

      def notify?(*args)
        enabled? && Isolator.enabled? && Isolator.within_transaction? && !ignored?(*args)
      end

      def ignore_if
        ignores << Proc.new
      end

      def ignores
        @ignores ||= []
      end

      def ignored?(*args)
        ignores.any? { |block| block.call(*args) }
      end

      private

      def build_exception(obj, args)
        klass = exception_class || Isolator::UnsafeOperationError
        details = details_message.call(obj, args) if details_message
        klass.new(exception_message, details: details)
      end
    end
  end
end
