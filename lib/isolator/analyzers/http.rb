module Isolator
  module Analyzers
    class HTTP < Base
      def start
        Sniffer.enable!
      end

      def find_something?
        !Sniffer.data[0].nil?
      end

      def end
        Sniffer.clear! and Sniffer.disable!
      end

      def raise_error!
        raise Errors::HTTPError
      end
    end
  end
end
