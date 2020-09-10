# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications listener
  # Used for ActiveRecord and ROM::SQL (when instrumentation is available)
  module ActiveSupportSubscriber
    START_PATTERN = %r{(\ABEGIN|\ASAVEPOINT)}xi
    FINISH_PATTERN = %r{(\ACOMMIT|\AROLLBACK|\ARELEASE|\AEND TRANSACTION)}xi

    def self.subscribe!(event)
      ::ActiveSupport::Notifications.subscribe(event) do |_name, _start, _finish, _id, query|
        connection_id = query[:connection_id] || query[:connection]&.object_id || 0
        Isolator.incr_transactions!(connection_id) if START_PATTERN.match?(query[:sql])
        Isolator.decr_transactions!(connection_id) if FINISH_PATTERN.match?(query[:sql])
      end
    end
  end
end
