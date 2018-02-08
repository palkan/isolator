# frozen_string_literal: true

module Isolator
  module ActiveRecordAdapter
    module IsolatedTransactions
      def self.extended(base)
        class << base
          alias_method :transaction_without_isolator, :transaction
          alias_method :transaction, :transaction_with_isolator
        end
      end

      def transaction_with_isolator(options = {}, &block)
        Isolator.enable!
        result = transaction_without_isolator(options, &block)
        Isolator.disable!
        result
      end
    end
  end
end

ActiveRecord::Base.extend(Isolator::ActiveRecordAdapter::IsolatedTransactions)
