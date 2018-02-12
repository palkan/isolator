module Isolator
  module Analyzers
    # Basic analyzer inferface
    class Base
      def start; end
      def end; end
      def find_something?; end
    end
  end
end
