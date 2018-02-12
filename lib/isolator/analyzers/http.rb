module Isolator
  module Analyzers
    class HTTP < Base
      def start
        Sniffer.enable!
      end

      def find_something?
        !Sniffer.data[0].nil?
      end

      def infer!
        if find_something?
          Sniffer.clear! && Sniffer.disable!
          raise Errors::HTTPError
        end
      end
    end
  end
end
