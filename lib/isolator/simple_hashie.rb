# frozen_string_literal: true

module Isolator
  # Hash with key accessors
  class SimpleHashie < Hash
    def method_missing(key, *args, &block)
      key_str = key.to_s

      if key_str.end_with?("=")
        self[key_str.tr('=')] = args.first 
      else
        fetch(key_str) { super }
      end
    end

    def respond_to_missing?(key)
      key_str = key.to_s
      if key_str.end_with?("=")
        key?(key_str.tr('=')) || super
      else
        key?(key_str) || super
      end
    end
  end
end
