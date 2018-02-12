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
          handle_errors!
        end
      end

      def handle_errors!
        if Isolator.configuration.logger
          Isolator.logger.debug("Forbidden HTTP call within transaction was made!")
        end

        if Isolator.configuration.raise_errors
          raise Errors::HTTPError
        end
      end
    end
  end
end
