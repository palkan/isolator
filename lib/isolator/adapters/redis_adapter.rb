# frozen_string_literal: true

module Isolator
  module RedisAdapter
    module Client
      def self.included(base)
        base.class_eval do
          alias_method :process_without_isolator, :process
          alias_method :process, :process_with_isolator
        end
      end

      def process_with_isolator(commands, &block)
        Isolator.notify(klass: self, backtrace: caller) if Isolator.enabled?

        process_without_isolator(commands, &block)
      end

      def isolator_exception
        ::Isolator::RedisAccessError
      end
    end
  end
end

Redis::Client.include(Isolator::RedisAdapter::Client) if defined?(Redis::Client)
