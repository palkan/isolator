module Isolator
  module Adapters
    module ActiveRecord
      def self.included(base)
        base.class_eval do
          alias_method :orig_transaction, :transaction
          alias_method :transaction, :transaction_with_isolator
        end
      end

      def transaction_with_isolator(options = {}, &block)
        Isolator.start_analyze do
          orig_transaction(options, &block)
        end
      end
    end
  end
end

ActiveRecord::Transactions.send(:include, Isolator::Adapters::ActiveRecord) if defined?(ActiveRecord)
