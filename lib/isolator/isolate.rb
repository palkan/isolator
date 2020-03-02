# frozen_string_literal: true

module Isolator
  # Add .isolate function to build and register adapters
  module Isolate
    def isolate(id, **options)
      raise "Adapter already registered: #{id}" if Isolator.adapters.key?(id.to_s)
      adapter = AdapterBuilder.call(**options)
      Isolator.adapters[id.to_s] = adapter
    end
  end
end
