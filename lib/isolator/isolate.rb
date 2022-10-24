# frozen_string_literal: true

module Isolator
  # Add .isolate function to build and register adapters
  module Isolate
    def isolate(id, **options)
      raise "Adapter already registered: #{id}" if Isolator.has_adapter?(id)
      adapter = AdapterBuilder.call(**options)
      Isolator.adapters[id.to_s] = adapter
    end

    def remove_adapter(id)
      if (adapter = Isolator.adapters.delete(id.to_s))
        adapter.restore if adapter.respond_to?(:restore)
      end
    end
  end
end
