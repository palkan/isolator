# frozen_string_literal: true

require "isolator/version"
require "isolator/configuration"
require "isolator/adapter_builder"
require "isolator/notifier"
require "isolator/errors"
require "isolator/simple_hashie"
require "isolator/ignorer"

require "isolator/callbacks"
require "isolator/isolate"

require "isolator/ext/thread_fetch"

# Isolator detects unsafe operations performed within DB transactions.
module Isolator
  using Isolator::ThreadFetch

  # nil: a transaction on a connection ActiveRecord doesn't own (e.g., ROM)
  # :active_record: a transaction ActiveRecord's transaction manager tracks
  # :active_record_raw: a raw BEGIN or SAVEPOINT on an ActiveRecord connection
  TRANSACTION_KINDS = [nil, :active_record, :active_record_raw].freeze

  class ThreadStateProxy
    attr_reader :prefix

    def initialize(prefix = "isolator_")
      @prefix = prefix
    end

    def [](key)
      Thread.current[:"#{prefix}#{key}"]
    end

    def []=(key, value)
      Thread.current[:"#{prefix}#{key}"] = value
    end
  end

  class << self
    attr_accessor :default_threshold, :default_connection_id

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def notify(exception:, backtrace:)
      Notifier.new(exception, backtrace).call
    end

    def enable!
      state[:disabled] = false
    end

    def disable!
      state[:disabled] = true
    end

    # Accepts block and disable Isolator within
    def disable
      return yield if disabled?
      res = nil
      begin
        disable!
        res = yield
      ensure
        enable!
      end
      res
    end

    # Accepts block and enable Isolator within
    def enable
      return yield if enabled?
      res = nil
      begin
        enable!
        res = yield
      ensure
        disable!
      end
      res
    end

    def transactions_threshold=(val)
      set_connection_threshold(val)
    end

    def transactions_threshold(connection_id = default_connection_id.call)
      connection_threshold(connection_id)
    end

    def current_transactions(connection_id = default_connection_id.call)
      state[:transactions]&.[](connection_id) || 0
    end

    def all_transactions
      state[:transactions] || {}
    end

    def connection_threshold(connection_id)
      state[:thresholds]&.[](connection_id) || default_threshold
    end

    def set_connection_threshold(val, connection_id = default_connection_id.call)
      state[:thresholds] ||= Hash.new { |h, k| h[k] = Isolator.default_threshold }
      state[:thresholds][connection_id] = val
      shared_thresholds_lock.synchronize { shared_thresholds[connection_id] = val }

      debug!("Threshold value was changed for connection #{connection_id}: #{val}")
    end

    def incr_thresholds!
      self.default_threshold += 1
      debug!("Thresholds were incremented")

      shared_thresholds_lock.synchronize { shared_thresholds.transform_values!(&:succ) }

      return unless state[:thresholds]

      state[:thresholds].transform_values!(&:succ)
    end

    def decr_thresholds!
      self.default_threshold -= 1
      debug!("Thresholds were decremented")

      shared_thresholds_lock.synchronize { shared_thresholds.transform_values!(&:pred) }

      return unless state[:thresholds]

      state[:thresholds].transform_values!(&:pred)
    end

    def incr_transactions!(connection_id = default_connection_id.call, kind: nil)
      check_transaction_kind(kind)

      state[:transactions] ||= Hash.new { |h, k| h[k] = 0 }
      state[:transactions][connection_id] += 1
      incr_active_record_transactions(connection_id) if kind == :active_record
      (state[:active_record_connection_ids] ||= {})[connection_id] = true if kind

      # Workaround to track threshold changes made before opening a connection
      pending_threshold = state[:thresholds]&.delete(0)
      if pending_threshold
        state[:thresholds][connection_id] = pending_threshold

        shared_thresholds_lock.synchronize do
          shared_pending_threshold = shared_thresholds.delete(0)
          shared_thresholds[connection_id] = shared_pending_threshold if shared_pending_threshold
        end
      end

      debug!("Transaction opened for connection #{connection_id} (total: #{state[:transactions][connection_id]}, threshold: #{state[:thresholds]&.fetch(connection_id, default_threshold)})")

      current_depth = current_transactions(connection_id)
      threshold = connection_threshold(connection_id)

      start! if current_depth == threshold
      if current_depth >= threshold
        event = {connection_id: connection_id, depth: current_depth - threshold + 1}.freeze
        notify!(:begin, event)
      end
    end

    def decr_transactions!(connection_id = default_connection_id.call, kind: nil)
      check_transaction_kind(kind)

      current = state[:transactions]&.[](connection_id) || 0

      if current <= 0
        warn "Trying to finalize an untracked transaction"
        return
      end

      state[:transactions][connection_id] -= 1
      decr_active_record_transactions(connection_id) if kind == :active_record

      current_depth = current_transactions(connection_id)
      threshold = connection_threshold(connection_id)

      if current_depth >= threshold - 1
        event = {connection_id: connection_id, depth: current_depth - threshold + 1}.freeze
        notify!(:end, event)
      end

      finish! if current_depth == (threshold - 1)

      if state[:transactions][connection_id].zero?
        state[:transactions].delete(connection_id)
        state[:active_record_connection_ids]&.delete(connection_id)
      end

      debug!("Transaction closed for connection #{connection_id} (total: #{state[:transactions].fetch(connection_id, 0)}, threshold: #{state[:thresholds]&.[](connection_id) || default_threshold})")
    end

    # Moves an already counted raw transaction to the ones ActiveRecord's transaction manager tracks
    def claim_raw_transaction(connection_id)
      incr_active_record_transactions(connection_id)
    end

    def clear_transactions!
      state[:transactions]&.clear
      state[:active_record_transactions]&.clear
      state[:active_record_connection_ids]&.clear
    end

    def within_transaction?
      if active_record_depth_available?
        within_active_record_transaction?
      else
        within_counted_transaction?
      end
    end

    def enabled?
      !disabled?
    end

    def disabled?
      state[:disabled] == true
    end

    def adapters
      @adapters ||= Isolator::SimpleHashie.new
    end

    def has_adapter?(id)
      adapters.key?(id.to_s)
    end

    def load_ignore_config(path)
      warn "[DEPRECATION] `load_ignore_config` is deprecated. Please use `Isolator::Ignorer.prepare` instead."
      Isolator::Ignorer.prepare(path: path)
    end

    include Isolator::Isolate
    include Isolator::Callbacks

    attr_accessor :debug_enabled, :backtrace_cleaner, :backtrace_length

    private

    attr_accessor :state

    # The transaction subscriber (Rails 7.1+) tells counted transactions apart from the ones ActiveRecord tracks,
    # so ActiveRecord's own transaction depth can be used instead of counted events, which go stale after a reset
    def active_record_depth_available?
      !defined?(::Isolator::ActiveSupportTransactionSubscriber).nil?
    end

    def within_counted_transaction?
      state[:transactions]&.each do |connection_id, transaction_count|
        return true if transaction_count >= connection_threshold(connection_id)
      end
      false
    end

    # Compares ActiveRecord's real transaction depth with the thresholds instead of counted events.
    # Transactions ActiveRecord doesn't track (raw BEGIN statements, other ORMs) are still counted.
    def within_active_record_transaction?
      connection_ids = []

      ::ActiveRecord::Base.connection_handler.connection_pool_list(:all).each do |pool|
        connection = pool.active_connection?
        next unless connection

        connection_id = connection.object_id
        # Pools can share a connection (e.g., replicas in transactional tests)
        next if connection_ids.include?(connection_id)

        connection_ids << connection_id

        depth = connection.open_transactions + raw_transactions(connection_id)
        return true if depth >= shared_connection_threshold(connection_id)
      end

      # An ActiveRecord connection this thread no longer holds (returned to the pool, or discarded
      # after a reset) can't have this thread's transactions open anymore
      state[:transactions]&.any? do |connection_id, _|
        !connection_ids.include?(connection_id) &&
          !state[:active_record_connection_ids]&.key?(connection_id) &&
          raw_transactions(connection_id) >= shared_connection_threshold(connection_id)
      end || false
    end

    def raw_transactions(connection_id)
      total = state[:transactions]&.[](connection_id) || 0
      active_record = state[:active_record_transactions]&.[](connection_id) || 0

      [total - active_record, 0].max
    end

    def incr_active_record_transactions(connection_id)
      state[:active_record_transactions] ||= Hash.new { |h, k| h[k] = 0 }
      state[:active_record_transactions][connection_id] += 1
    end

    def decr_active_record_transactions(connection_id)
      active_record = state[:active_record_transactions]
      return unless active_record&.[](connection_id)&.positive?

      active_record[connection_id] -= 1
      active_record.delete(connection_id) if active_record[connection_id].zero?
    end

    # Thresholds describe a connection's wrapper transactions, so they are shared with every
    # thread using that connection (e.g., the server threads in system tests)
    def shared_connection_threshold(connection_id)
      shared_thresholds_lock.synchronize { shared_thresholds[connection_id] } || default_threshold
    end

    attr_reader :shared_thresholds, :shared_thresholds_lock

    def check_transaction_kind(kind)
      return if TRANSACTION_KINDS.include?(kind)

      raise ArgumentError, "Unknown transaction kind: #{kind.inspect}. Expected one of: #{TRANSACTION_KINDS.map(&:inspect).join(", ")}"
    end

    def debug!(msg)
      return unless debug_enabled

      separator = " ↳ "

      begin
        msg = "[ISOLATOR DEBUG] #{msg}"
        if backtrace_cleaner && backtrace_length.positive?
          source = extract_source_location(caller)

          msg = "#{msg}\n #{separator}#{source.join("\n")}" unless source.empty?
        end

        $stdout.puts(colorize_debug(msg))
      rescue Encoding::CompatibilityError
        should_retry = separator != " - "
        separator = " - "
        retry if should_retry
      end
    end

    def extract_source_location(locations)
      backtrace_cleaner.call(locations.lazy)
        .take(backtrace_length).to_a
    end

    def colorize_debug(msg)
      return msg unless $stdout.tty?

      "\u001b[31;1m#{msg}\u001b[0m"
    end
  end

  self.state = ThreadStateProxy.new
  @shared_thresholds = {}
  @shared_thresholds_lock = Mutex.new
  self.default_threshold = 1
  self.default_connection_id = -> { ActiveRecord::Base.connected? ? ActiveRecord::Base.connection.object_id : 0 }
  self.debug_enabled = ENV["ISOLATOR_DEBUG"] == "true"
  self.backtrace_length = ENV.fetch("ISOLATOR_BACKTRACE_LENGTH", 1).to_i
end

require "isolator/orm_adapters"

require "isolator/adapters"
require "isolator/railtie" if defined?(Rails)
require "isolator/database_cleaner_support" if defined?(DatabaseCleaner)

# Built-in extensions
require "isolator/plugins/concurrent_database_transactions"
require "isolator/plugins/database_subtransactions"
