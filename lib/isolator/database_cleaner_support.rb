# frozen_string_literal: true

module Isolator
  module DatabaseCleanerSupport
    def start
      super
      Isolator.transactions_threshold += 1
    end

    def clean
      Isolator.transactions_threshold -= 1
      super
    end
  end
end

begin
  require "database_cleaner/active_record/transaction"

  ::DatabaseCleaner::ActiveRecord::Transaction.prepend(Isolator::DatabaseCleanerSupport)
rescue LoadError
  require "database_cleaner/configuration"

  ::DatabaseCleaner::Configuration.prepend(Isolator::DatabaseCleanerSupport)
end
