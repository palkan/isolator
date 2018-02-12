# frozen_string_literal: true

module Isolator
  module ActiveRecordAdapter
    module IsolatedTransactions
      def transaction(options = {}, &block)
        Isolator.enable!
        result = super(options, &block)
        Isolator.disable!
        result
      end
    end
  end
end

ActiveRecord::Base.singleton_class.prepend Isolator::ActiveRecordAdapter::IsolatedTransactions
