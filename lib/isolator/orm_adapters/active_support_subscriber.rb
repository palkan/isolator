# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications listener
  # Used for ActiveRecord and ROM::SQL (when instrumentation is available)
  module ActiveSupportSubscriber
    START_PATTERN = %r{(\ABEGIN|\ASAVEPOINT)}xi
    FINISH_PATTERN = %r{(\ACOMMIT|\AROLLBACK|\ARELEASE|\AEND TRANSACTION)}xi

    class Subscriber
      def start(event, id, payload)
        return unless start_event?(payload[:sql])

        connection_id = extract_connection_id(payload)

        Isolator.incr_transactions!(connection_id)
      end

      def finish(event, id, payload)
        return unless finish_event?(payload[:sql])

        connection_id = extract_connection_id(payload)

        Isolator.decr_transactions!(connection_id)
      end

      private

      def start_event?(sql)
        START_PATTERN.match?(sanitize_query(sql))
      end

      def finish_event?(sql)
        FINISH_PATTERN.match?(sanitize_query(sql))
      end

      # Prevents "ArgumentError: invalid byte sequence in UTF-8" by replacing invalid byte sequence with "?"
      def sanitize_query(sql)
        sql.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "?")
      end

      def extract_connection_id(payload)
        payload[:connection_id] || payload[:connection]&.object_id || 0
      end
    end

    def self.subscribe!(event)
      subscriber = Subscriber.new
      ::ActiveSupport::Notifications.subscribe(event, subscriber)
    end
  end
end
