# frozen_string_literal: true

module Isolator
  module ThreadFetch # :nodoc:
    refine Thread do
      def fetch(key, fallback = :__undef__)
        raise KeyError, "key not found: #{key}" if !key?(key) && fallback == :__undef__

        self[key] || fallback
      end
    end
  end
end
