module Isolator
  class AdapterBuilder < Module
    def initialize(method_to_isolate, exception = Isolator::UnsafeOperationError)
      alias_methods(method_to_isolate)
      patch_method(method_to_isolate)
      define_exception_method(exception)
    end

    def alias_methods(method_name)
      define_singleton_method :included do |base|
        base.class_eval do
          alias_method "#{method_name}_without_isolator", method_name
          alias_method method_name, "#{method_name}_with_isolator"
        end
      end
    end

    def patch_method(method_name)
      define_method "#{method_name}_with_isolator" do |*args, &block|
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        send "#{method_name}_without_isolator", *args, &block
      end
    end

    def define_exception_method(exception)
      define_method :isolator_exception do
        exception
      end
    end
  end
end
