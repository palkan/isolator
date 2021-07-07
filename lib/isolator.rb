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

  class ThreadStateProxy
    attr_reader :prefix

    def initilize(prefix = "isolator_")
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

    def set_connection_threshold(val, connection_id = default_connection_id.call)
      state[:thresholds] ||= Hash.new { |h, k| h[k] = Isolator.default_threshold }
      state[:thresholds][connection_id] = val

      debug!("Threshold value was changed for connection #{connection_id}: #{val}")
    end

    def incr_thresholds!
      self.default_threshold += 1
      return unless state[:thresholds]

      state[:thresholds].transform_values!(&:succ)

      debug!("Thresholds were incremented")
    end

    def decr_thresholds!
      self.default_threshold -= 1
      return unless state[:thresholds]

      state[:thresholds].transform_values!(&:pred)

      debug!("Thresholds were decremented")
    end

    def incr_transactions!(connection_id = default_connection_id.call)
      state[:transactions] ||= Hash.new { |h, k| h[k] = 0 }
      state[:transactions][connection_id] += 1

      # Workaround to track threshold changes made before opening a connection
      pending_threshold = state[:thresholds]&.delete(0)
      if pending_threshold
        state[:thresholds][connection_id] = pending_threshold
      end

      debug!("Transaction opened for connection #{connection_id} (total: #{state[:transactions][connection_id]}, threshold: #{state[:thresholds]&.fetch(connection_id, default_threshold)})")

      start! if current_transactions(connection_id) == connection_threshold(connection_id)
    end

    def decr_transactions!(connection_id = default_connection_id.call)
      state[:transactions][connection_id] -= 1

      finish! if current_transactions(connection_id) == (connection_threshold(connection_id) - 1)

      state[:transactions].delete(connection_id) if state[:transactions][connection_id].zero?

      debug!("Transaction closed for connection #{connection_id} (total: #{state[:transactions][connection_id]}, threshold: #{state[:thresholds]&.[](connection_id) || default_threshold})")
    end

    def remove_connection!(connection_id)
      state[:transactions]&.delete(connection_id)
    end

    def clear_transactions!
      state[:transactions]&.clear
    end

    def within_transaction?
      state[:transactions]&.each do |connection_id, transaction_count|
        return true if transaction_count >= connection_threshold(connection_id)
      end
      false
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

    def load_ignore_config(path)
      warn "[DEPRECATION] `load_ignore_config` is deprecated. Please use `Isolator::Ignorer.prepare` instead."
      Isolator::Ignorer.prepare(path: path)
    end

    include Isolator::Isolate
    include Isolator::Callbacks

    attr_accessor :debug_enabled, :backtrace_cleaner, :backtrace_length

    private

    attr_accessor :state

    def connection_threshold(connection_id)
      state[:thresholds]&.[](connection_id) || default_threshold
    end

    def debug!(msg)
      return unless debug_enabled
      msg = "[ISOLATOR DEBUG] #{msg}"

      if backtrace_cleaner && backtrace_length.positive?
        source = extract_source_location(caller)

        msg = "#{msg}\n  ↳ #{source.join("\n")}" unless source.empty?
      end

      $stdout.puts(colorize_debug(msg))
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
  self.default_threshold = 1
  self.default_connection_id = -> { ActiveRecord::Base.connected? ? ActiveRecord::Base.connection.object_id : 0 }
  self.debug_enabled = ENV["ISOLATOR_DEBUG"] == "true"
  self.backtrace_length = ENV.fetch("ISOLATOR_BACKTRACE_LENGTH", 1).to_i
end

require "isolator/orm_adapters"

require "isolator/adapters"
require "isolator/railtie" if defined?(Rails)
require "isolator/database_cleaner_support" if defined?(DatabaseCleaner)
