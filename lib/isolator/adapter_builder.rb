# frozen_string_literal: true

require "isolator/adapters/base"

module Isolator
  # Builds adapter from provided params
  module AdapterBuilder
    def self.call(target, method_name, **options)
      adapter = Module.new do
        extend Isolator::Adapters::Base

        self.exception_class = options[:exception_class] if options.key?(:exception_class)
        self.exception_message = options[:exception_message] if options.key?(:exception_message)
      end

      add_patch_method adapter, target, method_name
      adapter
   end

    def self.add_patch_method(adapter, base, method_name)
      mod = Module.new do
        define_method method_name do |*args, &block|
          adapter.notify(caller) if adapter.notify_isolator?
          super(*args, &block)
        end
      end

      base.prepend mod
    end
  end
end
