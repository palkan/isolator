# frozen_string_literal: true

require 'net/http'

module Isolator
  module Adapters
    module NetHttpAdapter
      def self.included(base)
        base.class_eval do
          alias_method :request_without_isolator, :request
          alias_method :request, :request_with_isolator
        end
      end

      def request_with_isolator(req, body = nil, &block)
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        request_without_isolator(req, body, &block)
      end

      def isolator_exception
        ::Isolator::NetworkRequestError
      end
    end
  end
end

Net::HTTP.include(Isolator::Adapters::NetHttpAdapter)
