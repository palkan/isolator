module Isolator
  module Analyzers
    # Basic analyzer interface
    class Base
      def start; end
      def infer!; end
    end
  end
end
