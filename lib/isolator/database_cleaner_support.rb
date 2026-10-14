# frozen_string_literal: true

require "database_cleaner/active_record/base"
require "database_cleaner/active_record/transaction"
::DatabaseCleaner::ActiveRecord::Transaction.prepend(
  Module.new do
    def start
      super

      # Remembered for #clean, in case the connection gets replaced in between (e.g., reaped)
      connection_id = @isolator_connection_id = connection.object_id

      Isolator.set_connection_threshold(
        Isolator.transactions_threshold(connection_id) + 1,
        connection_id
      )
    end

    def clean
      connection_id = @isolator_connection_id || connection.object_id
      @isolator_connection_id = nil

      Isolator.set_connection_threshold(
        Isolator.transactions_threshold(connection_id) - 1,
        connection_id
      )

      super
    end

    private

    def connection
      if Gem::Version.new("7.2") <= Gem::Version.new(Rails::VERSION::STRING)
        connection_class.lease_connection
      else
        connection_class.connection
      end
    end
  end
)
