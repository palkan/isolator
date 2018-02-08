module Isolator
  class AdapterBuilder < Module
    def initialize(*methods_to_isolate, exception: Isolator::UnsafeOperationError)
      methods_to_isolate.each { |name| patch_method name }
      define_exception_method(exception)
    end

    def patch_method(method_name)
      define_method method_name do |*args, &block|
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        super
      end
    end

    def define_exception_method(exception)
      define_method :isolator_exception do
        exception
      end
    end
  end
end
