# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications subscriber for "transaction.active_record" event (new in Rails 7.1)
  module ActiveSupportTransactionSubscriber
    class Subscriber < ActiveSupportSubscriber::Subscriber
      attr_reader :stacks

      def initialize
        @stacks = Hash.new { |h, k| h[k] = [] }
      end

      def start(event, id, payload)
        if event.start_with?("transaction.")
          connection_id = extract_transaction_connection_id(payload)

          # transaction.active_record can be issued without a query (when we restart the transaction),
          # so we should add a new one on the stack.
          # Example: https://github.com/rails/rails/blob/ce49fa9b31cd4a21d43db39d0cea364bce28b51d/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L337
          if stacks[connection_id].last == :raw
            # Update the type of the last transaction event
            stacks[connection_id].pop
            stacks[connection_id] << :transaction
          else
            stacks[connection_id] << :transaction
            Isolator.incr_transactions!(connection_id)
          end
        end
      end

      def finish(event, id, payload)
        if event.start_with?("sql.")
          if start_event?(payload[:sql])
            connection_id = extract_connection_id(payload)

            stacks[connection_id] << :raw

            Isolator.incr_transactions!(connection_id)
          end

          if finish_event?(payload[:sql])
            connection_id = extract_connection_id(payload)

            # Decrement only if the transaction was started in the raw mode,
            # otherwise we should wait for the "transaction" event
            if stacks[connection_id].last == :raw
              stacks[connection_id].pop
              Isolator.decr_transactions!(connection_id)
            end
          end
        end

        if event.start_with?("transaction.")
          connection_id = extract_transaction_connection_id(payload)
          stacks[connection_id].pop

          Isolator.decr_transactions!(connection_id)
        end
      end

      private

      def extract_transaction_connection_id(payload)
        payload[:connection]&.object_id || 0
      end
    end

    def self.subscribe!(event = "transaction.active_record", sql_event = "sql.active_record")
      subscriber = Subscriber.new
      ::ActiveSupport::Notifications.subscribe(event, subscriber)
      ::ActiveSupport::Notifications.subscribe(sql_event, subscriber)
    end
  end
end
