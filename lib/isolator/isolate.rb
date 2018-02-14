# frozen_string_literal: true

module Isolator
  # Add .isolate function to build and register adapters
  module Isolate
    def isolate(id, target_module, method_name, **options)
      raise "Adapter already registered: #{id}" if Isolator.adapters.key?(id.to_s)
      adapter = AdapterBuilder.call(target_module, method_name, **options)
      Isolator.adapters[id.to_s] = adapter
    end
  end
end
