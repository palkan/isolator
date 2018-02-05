# frozen_string_literal: true

module Isolator
  module Adapters
    module HTTPAdapter
      def self.included(base)
        base.class_eval do
          alias_method :request_without_isolator, :request
          alias_method :request, :request_with_isolator
        end
      end

      def request_with_isolator(verb, uri, opts = {})
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        request_without_isolator(verb, uri, opts)
      end

      def isolator_exception
        ::Isolator::NetworkRequestError
      end
    end
  end
end

HTTP::Client.send(:include, Isolator::Adapters::HTTPAdapter) if defined?(::HTTP::Client)
