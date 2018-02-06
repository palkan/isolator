# frozen_string_literal: true

require "anyway"
require "uniform_notifier"

require "isolator/version"
require "isolator/adapter_builder"
require "isolator/notifier"
require "isolator/errors"
require "isolator/config"

require "isolator/orm_adapters/active_record_adapter"

require "isolator/adapters/ethon_adapter"
require "isolator/adapters/patron_adapter"
require "isolator/adapters/httpclient_adapter"
require "isolator/adapters/http_adapter"
require "isolator/adapters/net_http_adapter"

require "isolator/adapters/redis_adapter"

module Isolator
  class << self
    def notify(klass:, backtrace: [])
      Notifier.new(klass, backtrace).call
    end

    def enable!
      Thread.current[:isolator] = true
    end

    def disable!
      Thread.current[:isolator] = false
    end

    def enabled?
      Thread.current[:isolator] == true
    end

    def config
      @config ||= Config.new
    end
  end
end
