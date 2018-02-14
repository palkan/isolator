# frozen_string_literal: true

module Isolator
  # ActiveSupport notifications listener for sql.active_record events
  module ActiveRecordListener
    EVENT = "sql.active_record"

    START_PATTERN = %r{(\ABEGIN|\ASAVEPOINT)}xi
    FINISH_PATTERN = %r{(\ACOMMIT|\AROLLBACK|\ARELEASE|\AEND TRANSACTION)}xi

    def self.subscribe!
      ::ActiveSupport::Notifications.subscribe(EVENT) do |_name, _start, _finish, _id, query|
        Isolator.incr_transactions! if query[:sql] =~ START_PATTERN
        Isolator.decr_transactions! if query[:sql] =~ FINISH_PATTERN
      end
    end
  end
end

Isolator::ActiveRecordListener.subscribe!
