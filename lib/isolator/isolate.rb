# frozen_string_literal: true

module Isolator
  # Add .isolate function to build and register adapters
  module Isolate
    def isolate(id, **options)
      AdapterBuilder.call(**options).tap do |adapter|
        Isolator.adapters.add(id.to_s, adapter)
      end
    end
  end
end
