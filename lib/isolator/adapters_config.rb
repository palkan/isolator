# frozen_string_literal: true

module Isolator
  # Wraps the adapter config and provides accessor by name
  class AdaptersConfig
    def add(id, adapter)
      raise "Adapter already registered: #{id}" if respond_to?(id)
      define_singleton_method(id) { adapter }
    end
  end
end
