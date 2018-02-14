# frozen_string_literal: true

require "isolator/version"
require "isolator/configuration"
require "isolator/adapter_builder"
require "isolator/notifier"
require "isolator/errors"
require "isolator/simple_hashie"

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

    def incr_transactions!
      return unless enabled?
      Thread.current[:isolator_transactions] =
        Thread.current.fetch(:isolator_transactions, 0) + 1
      start! if Thread.current.fetch(:isolator_transactions) == 1
    end

    def decr_transactions!
      return unless enabled?
      Thread.current[:isolator_transactions] =
        Thread.current.fetch(:isolator_transactions) - 1
      finish! if Thread.current.fetch(:isolator_transactions) == 0
    end

    def clear_transactions!
      Thread.current[:isolator_transactions] = 0
    end

    def within_transaction?
      Thread.current.fetch(:isolator_transactions, 0) > 0
    end

    def enabled?
      Thread.current[:isolator_disabled] != true
    end

    def adapters
      @adapters ||= Isolator::SimpleHashie.new
    end

    include Isolator::Isolate
    include Isolator::Callbacks
  end
end

require "isolator/orm_adapters"
require "isolator/adapters"
