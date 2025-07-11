# frozen_string_literal: true

require "database_cleaner/active_record/base"
require "database_cleaner/active_record/transaction"
::DatabaseCleaner::ActiveRecord::Transaction.prepend(
  Module.new do
    def start
      super
      connection_id = connection_class.connection.object_id
      Isolator.set_current_connection_id(connection_id, context: :database_cleaner)
      Isolator.set_connection_threshold(
        Isolator.transactions_threshold(connection_id) + 1,
        connection_id
      )
    end

    def clean
      connection_id = connection_class.connection.object_id
      return unless connection_id == Isolator.current_connection_id(context: :database_cleaner)
      Isolator.set_connection_threshold(
        Isolator.transactions_threshold(connection_id) - 1,
        connection_id
      )
      super
    end
  end
)
