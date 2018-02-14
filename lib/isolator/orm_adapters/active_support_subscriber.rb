# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications listener
  # Used for ActiveRecord and ROM::SQL (when instrumentation is available)
  module ActiveSupportSubscriber
    START_PATTERN = %r{(\ABEGIN|\ASAVEPOINT)}xi
    FINISH_PATTERN = %r{(\ACOMMIT|\AROLLBACK|\ARELEASE|\AEND TRANSACTION)}xi

    def self.subscribe!(event)
      ::ActiveSupport::Notifications.subscribe(event) do |_name, _start, _finish, _id, query|
        Isolator.incr_transactions! if query[:sql] =~ START_PATTERN
        Isolator.decr_transactions! if query[:sql] =~ FINISH_PATTERN
      end
    end
  end
end
