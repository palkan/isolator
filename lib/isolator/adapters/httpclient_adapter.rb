# frozen_string_literal: true

module Isolator
  module Adapters
    module HTTPClientAdapter
      def self.included(base)
        base.class_eval do
          alias_method :do_get_block_without_isolator, :do_get_block
          alias_method :do_get_block, :do_get_block_with_isolator
        end
      end

      def do_get_block_with_isolator(req, proxy, conn, &block)
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        do_get_block_without_isolator(req, proxy, conn, &block)
      end

      def isolator_exception
        ::Isolator::NetworkRequestError
      end
    end
  end
end

HTTPClient.send(:include, Isolator::Adapters::HTTPClientAdapter) if defined?(::HTTPClient)
