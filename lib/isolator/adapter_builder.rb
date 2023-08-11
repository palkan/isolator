# frozen_string_literal: true

require "isolator/adapters/base"

module Isolator
  # Builds adapter from provided params
  module AdapterBuilder
    class << self
      def call(target: nil, method_name: nil, **options)
        adapter = Module.new do
          extend Isolator::Adapters::Base

          self.exception_class = options[:exception_class] if options.key?(:exception_class)
          self.exception_message = options[:exception_message] if options.key?(:exception_message)
          self.details_message = options[:details_message] if options.key?(:details_message)
        end

        mod = build_mod(method_name, adapter)
        if target && mod
          target.prepend(mod)
          adapter.define_singleton_method(:restore) do
            mod.remove_method(method_name)
          end
        end

        adapter
      end

      private

      def build_mod(method_name, adapter)
        return nil unless method_name

        Module.new do
          define_method method_name do |*args, **kwargs, &block|
            # check if we are even notifying before calling `caller`, which is well known to be slow
            adapter.notify(caller, self, *args, **kwargs) if adapter.notify?(*args, **kwargs)
            super(*args, **kwargs, &block)
          end
        end
      end
    end
  end
end
