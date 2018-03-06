# frozen_string_literal: true

require "forwardable"

module Isolator
  module Adapters
    # Wraps the adapter config and provides accessor by name
    class Config
      include Enumerable
      extend Forwardable
      def_delegators :hash_config, :each, :[]

      def register(id, adapter)
        raise "Adapter already registered: #{id}" if respond_to?(id)
        define_singleton_method(id) { self[id] }
        hash_config[id] = adapter
      end

      private

      def hash_config
        @hash_config ||= {}
      end
    end
  end
end
