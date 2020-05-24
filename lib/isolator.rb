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

    def transactions_threshold
      Thread.current.fetch(:isolator_threshold, 1)
    end

    def transactions_threshold=(val)
      # Do we need separate threshold per connection?
      Thread.current[:isolator_threshold] = val
    end

    def incr_transactions!(connection = ActiveRecord::Base.connection)
      Thread.current[:isolator_connection_transactions] ||= {}
      Thread.current[:isolator_connection_transactions][identifier_for(connection)] =
        current_transactions(connection) + 1
      start! if current_transactions(connection) == transactions_threshold
    end

    def decr_transactions!(connection = ActiveRecord::Base.connection)
      # Decrementing for unknown connection should raise error.
      Thread.current[:isolator_connection_transactions][identifier_for(connection)] =
        current_transactions(connection) - 1
      finish! if current_transactions(connection) == (transactions_threshold - 1)
    end

    def clear_transactions!
      # Note: Hash#transform_values is only compatible with ruby 2.5+
      Thread.current[:isolator_connection_transactions].transform_values! do |_val|
        0
      end
    end

    def within_transaction?
      Thread.current.fetch(:isolator_connection_transactions, {}).each_value do |transaction_count|
        return true if transaction_count >= transactions_threshold
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

    def identifier_for(connection)
      raise ArgumentError, 'Invalid connection' if connection.nil?
      # Is there a reason to distinguish further by user/pass?
      connection.instance_variable_get("@config").slice(:adapter, :host, :database)
    end

    def current_transactions(connection)
      Thread.current.fetch(:isolator_connection_transactions, {})[identifier_for(connection)] || 0
    end
  end
end

require "isolator/orm_adapters"

require "isolator/adapters"
require "isolator/railtie" if defined?(Rails)
require "isolator/database_cleaner_support" if defined?(DatabaseCleaner)
