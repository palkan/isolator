module Isolator
  module Errors
    class HTTPError < StandardError
      def to_s
        "HTTP calls within transaction not allowed"
      end
    end
  end
end
