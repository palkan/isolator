module Isolator
  class AdapterBuilder < Module
    def initialize(*methods_to_isolate, **options)
      define_conditions options
      methods_to_isolate.each { |name| patch_method name }
      define_exception_method options.fetch(:exception, Isolator::UnsafeOperationError)
    end

    def patch_method(method_name)
      define_method method_name do |*args, &block|
        Isolator.notify(klass: self, backtrace: caller) if notify_isolator?

        super(*args, &block)
      end
    end

    def define_exception_method(exception)
      define_method :isolator_exception do
        exception
      end
    end

    def define_conditions(conditions)
      define_method :notify_isolator? do
        Isolator::Guard.new(object: self, conditions: conditions).notify?
      end
    end
  end
end
