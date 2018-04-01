# frozen_string_literal: true

require "database_cleaner/active_record/transaction"

::DatabaseCleaner::ActiveRecord::Transaction.prepend(
  Module.new do
    def start
      super
      Isolator.transactions_threshold += 1
    end

    def clean
      Isolator.transactions_threshold -= 1
      super
    end
  end
)
