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

      def notify(backtrace, obj, *args, **kwargs)
        return unless notify?(*args, **kwargs)
        Isolator.notify(exception: build_exception(obj, args, kwargs), backtrace: backtrace)
      end

      def notify_on?(obj, *args, **kwargs)
        !ignore_on?(obj) && notify?(*args, **kwargs)
      end

      def notify?(...)
        enabled? && Isolator.enabled? && Isolator.within_transaction? && !ignored?(...)
      end

      def ignore_if(&block)
        ignores << block
      end

      def ignores
        @ignores ||= []
      end

      def ignored?(*args, **kwargs)
        ignores.any? { |block| block.call(*args, **kwargs) }
      end

      def ignore_on?(_obj)
        false
      end

      private

      def build_exception(obj, args, kwargs = {})
        klass = exception_class || Isolator::UnsafeOperationError
        details = build_details(obj, args, kwargs)
        klass.new(exception_message, details: details)
      end

      def build_details(obj, args, kwargs)
        return nil unless details_message

        case details_message.arity
        when 2, -2
          # Older users of details_message expected only two arguments. Add
          # kwargs hash as last argument, like in older Ruby.
          details_message.call(obj, args + [kwargs])
        when 3, -3
          # New signature separates args from kwargs
          details_message.call(obj, args, kwargs)
        when 1
          # Callback does not care about any args
          details_message.call(obj)
        else
          raise "Unexpected arity (#{details_message.arity}) for #{details_message.inspect}"
        end
      end
    end
  end
end
