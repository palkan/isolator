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
      Thread.current[:isolator_disabled] = false
    end

    def disable!
      Thread.current[:isolator_disabled] = true
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

    def set_connection_threshold(val, connection_id = default_connection_id.call)
      Thread.current[:isolator_connection_thresholds] ||= Hash.new { |h, k| h[k] = Isolator.default_threshold }
      Thread.current[:isolator_connection_thresholds][connection_id] = val
    end

    def incr_transactions!(connection_id = default_connection_id.call)
      Thread.current[:isolator_connection_transactions] ||= Hash.new { |h, k| h[k] = 0 }
      Thread.current[:isolator_connection_transactions][connection_id] += 1
      start! if current_transactions(connection_id) == connection_threshold(connection_id)
    end

    def decr_transactions!(connection_id = default_connection_id.call)
      Thread.current[:isolator_connection_transactions][connection_id] -= 1
      finish! if current_transactions(connection_id) == (connection_threshold(connection_id) - 1)
    end

    def clear_transactions!
      Thread.current[:isolator_connection_transactions]&.clear
    end

    def within_transaction?
      Thread.current.fetch(:isolator_connection_transactions, {}).each do |connection_id, transaction_count|
        return true if transaction_count >= connection_threshold(connection_id)
      end
      false
    end

    def enabled?
      !disabled?
    end

    def disabled?
      Thread.current[:isolator_disabled] == true
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

    private

    def current_transactions(connection_id)
      Thread.current.fetch(:isolator_connection_transactions, {})[connection_id] || 0
    end

    def connection_threshold(connection_id)
      Thread.current.fetch(:isolator_connection_thresholds, {})[connection_id] || default_threshold
    end
  end

  self.default_threshold = 1
  self.default_connection_id = -> { ActiveRecord::Base.connected? ? ActiveRecord::Base.connection.object_id : 0 }
end

require "isolator/orm_adapters"

require "isolator/adapters"
require "isolator/railtie" if defined?(Rails)
require "isolator/database_cleaner_support" if defined?(DatabaseCleaner)
