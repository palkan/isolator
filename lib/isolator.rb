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

  DEFAULT_CONNECTION_THRESHOLD = 1

  class << self
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

    def transactions_threshold(connection_id = base_connection_id)
      Thread.current.fetch(:isolator_connection_thresholds, {})[base_connection_id] || DEFAULT_CONNECTION_THRESHOLD
    end

    def transactions_threshold=(val)
      set_threshold(val, base_connection_id)
    end

    def set_threshold(val, connection_id)
      Thread.current[:isolator_connection_thresholds] ||= Hash.new { |h, k| h[k] = DEFAULT_CONNECTION_THRESHOLD }
      Thread.current[:isolator_connection_thresholds][connection_id] = val
    end

    def incr_transactions!(connection_id = base_connection_id)
      Thread.current[:isolator_connection_transactions] ||= Hash.new { |h, k| h[k] = 0 }
      Thread.current[:isolator_connection_transactions][connection_id] += 1
      start! if current_transactions(connection_id) == transactions_threshold(connection_id)
    end

    def decr_transactions!(connection_id = base_connection_id)
      Thread.current[:isolator_connection_transactions][identifier_for(connection)] -= 1
      finish! if current_transactions(connection_id) == (transactions_threshold(connection_id) - 1)
    end

    def clear_transactions!
      Thread.current[:isolator_connection_transactions].clear
    end

    def within_transaction?
      Thread.current.fetch(:isolator_connection_transactions, {}).each_value do |transaction_count|
        return true if transaction_count >= transactions_threshold(connection_id)
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

    include Isolator::Isolate
    include Isolator::Callbacks
    include Isolator::Ignorer

    private

    def base_connection_id(connection = ActiveRecord::Base.connection)
      raise ArgumentError, "Invalid connection" if connection.nil?
      connection.instance_variable_get("@config").slice(:adapter, :host, :database)
    end

    def current_transactions(connection_id)
      Thread.current.fetch(:isolator_connection_transactions, {})[connection_id] || 0
    end
  end
end

require "isolator/orm_adapters"

require "isolator/adapters"
require "isolator/railtie" if defined?(Rails)
require "isolator/database_cleaner_support" if defined?(DatabaseCleaner)
