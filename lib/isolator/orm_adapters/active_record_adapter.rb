# frozen_string_literal: true

module Isolator
  module ActiveRecordAdapter
    module IsolatedTransactions
      def transaction(options = {}, &block)
        with_isolator { super }
      end

      private

      def with_isolator
        Isolator.enable!

        yield
      ensure
        Isolator.disable!
      end
    end

    module Connection
      def connection
        Isolator::ActiveRecord::ConnectionDecorator.new(super)
      end
    end
  end
end

ActiveRecord::Base.singleton_class.prepend(
  Isolator::ActiveRecordAdapter::IsolatedTransactions,
  Isolator::ActiveRecordAdapter::Connection
)
