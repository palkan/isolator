# frozen_string_literal: true

module Isolator
  module EthonAdapter
    module Http
      def self.included(base)
        base.class_eval do
          alias_method :http_request_without_isolator, :http_request
          alias_method :http_request, :http_request_with_isolator
        end
      end

      def http_request_with_isolator(url, action_name, options = {})
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        http_request_without_isolator(url, action_name, options)
      end

      def isolator_exception
        ::Isolator::NetworkRequestError
      end
    end
  end
end

Ethon::Easy.send(:include, Isolator::EthonAdapter::Http) if defined?(::Ethon::Easy)
