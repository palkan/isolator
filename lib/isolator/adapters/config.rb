# frozen_string_literal: true

require "forwardable"

module Isolator
  module Adapters
    # Wraps the adapter config and provides accessor by name
    class Config
      include Enumerable
      extend Forwardable
      def_delegators :store, :each

      def register(id, adapter)
        raise "Adapter already registered: #{id}" if store.key?(id.to_s)
        store[id.to_s] = adapter
      end

      def [](adapter_id)
        store.fetch(adapter_id.to_s)
      end

      def method_missing(key, *_args)
        self[key] || super
      end

      def respond_to_missing?(key, *_args)
        key_str = key.to_s
        store.key?(key_str)
      end

      private

      def store
        @store ||= {}
      end
    end
  end
end
