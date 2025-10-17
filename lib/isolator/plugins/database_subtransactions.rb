# frozen_string_literal: true

module Isolator
  class Configuration
    attr_accessor :max_subtransactions_depth
  end

  class MaxSubtransactionsExceededError < UnsafeOperationError
    MESSAGE = "Allowed subtransaction amount exceeded"
  end

  Isolator.on_transaction_begin do |event|
    next if Isolator.config.max_subtransactions_depth.nil?

    depth = event[:depth]
    next unless (depth - 1) > Isolator.config.max_subtransactions_depth

    Isolator.notify(exception: MaxSubtransactionsExceededError.new, backtrace: caller)
  end
end
