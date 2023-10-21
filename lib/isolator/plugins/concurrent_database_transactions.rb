# frozen_string_literal: true

module Isolator
  class Configuration
    attr_accessor :disallow_per_thread_concurrent_transactions

    alias_method :disallow_per_thread_concurrent_transactions?, :disallow_per_thread_concurrent_transactions
  end

  class ConcurrentTransactionError < UnsafeOperationError
    MESSAGE = "You are trying to open a transaction while there is an open transation to another database." \
  end

  Isolator.before_isolate do
    next unless Isolator.config.disallow_per_thread_concurrent_transactions?

    isolated_connections = Isolator.all_transactions.count do |conn_id, depth|
      depth >= Isolator.connection_threshold(conn_id)
    end

    next unless isolated_connections > 1

    Isolator.notify(exception: ConcurrentTransactionError.new, backtrace: caller)
  end
end
