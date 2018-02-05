# frozen_string_literal: true

module Isolator
  module PatronAdapter
    def self.included(base)
      base.class_eval do
        alias_method :request_without_isolator, :request
        alias_method :request, :request_with_isolator
      end
    end

    def request_with_isolator(action_name, url, headers, options = {})
      Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

      request_without_isolator(action_name, url, headers, options)
    end

    def isolator_exception
      ::Isolator::NetworkRequestError
    end
  end
end

::Patron::Session.send(:include, Isolator::PatronAdapter) if defined?(::Patron::Session)
