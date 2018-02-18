# frozen_string_literal: true

module Isolator
  module Adapters
    # Used as a "template" for adapters
    module Base
      attr_accessor :exception_class, :exception_message

      def disable!
        @disabled = true
      end

      def enable!
        @disabled = false
      end

      def enabled?
        @disabled != true
      end

      def notify(backtrace)
        Isolator.notify(exception: build_exception, backtrace: backtrace)
      end

      def notify_isolator?(*args)
        enabled? && Isolator.within_transaction? && !ignored?(*args)
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

      def build_exception
        klass = exception_class || Isolator::UnsafeOperationError
        klass.new(exception_message)
      end
    end
  end
end
