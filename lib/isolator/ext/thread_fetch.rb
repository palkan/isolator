module Isolator
  module ThreadFetch
    refine Thread do
      def fetch(key, fallback = :__undef__)
        if !key?(key) && fallback == :__undef__
          raise KeyError, "key not found: #{key}"
        end

        self[key] || fallback
      end
    end
  end
end
