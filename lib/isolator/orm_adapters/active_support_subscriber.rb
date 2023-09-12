# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications listener
  # Used for ActiveRecord and ROM::SQL (when instrumentation is available)
  module ActiveSupportSubscriber
    START_PATTERN = %r{(\ABEGIN|\ASAVEPOINT)}xi
    FINISH_PATTERN = %r{(\ACOMMIT|\AROLLBACK|\ARELEASE|\AEND TRANSACTION)}xi
    SUBTR_START_PATTERN = %r{(\ASAVEPOINT)}i
    SUBTR_FINISH_PATTERN = %r{(\ARELEASE SAVEPOINT|\AROLLBACK TO SAVEPOINT)}i

    def self.subscribe!(event)
      ::ActiveSupport::Notifications.subscribe(event) do |_name, _start, _finish, _id, query|
        connection_id = query[:connection_id] || query[:connection]&.object_id || 0
        # Prevents "ArgumentError: invalid byte sequence in UTF-8" by replacing invalid byte sequence with "?"
        sanitized_query = query[:sql].encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "?")
        Isolator.incr_transactions!(connection_id) if START_PATTERN.match?(sanitized_query)
        Isolator.decr_transactions!(connection_id) if FINISH_PATTERN.match?(sanitized_query)

        if Isolator.config.substransactions_depth_threshold
          Isolator.incr_subtransactions!(connection_id) if SUBTR_START_PATTERN.match?(sanitized_query)
          Isolator.decr_subtransactions!(connection_id) if SUBTR_FINISH_PATTERN.match?(sanitized_query)
        end
      end
    end
  end
end
