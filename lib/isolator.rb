# frozen_string_literal: true

require "anyway"
require "uniform_notifier"

require "isolator/version"
require "isolator/adapter_builder"
require "isolator/notifier"
require "isolator/errors"
require "isolator/config"

require "isolator/orm_adapters/active_record_adapter" if defined?(ActiveRecord::Base)

require "isolator/adapters/ethon_adapter" if defined?(::Ethon::Easy)
require "isolator/adapters/patron_adapter" if defined?(::Patron::Session)
require "isolator/adapters/httpclient_adapter" if defined?(::HTTPClient)
require "isolator/adapters/http_adapter" if defined?(::HTTP::Client)
require "isolator/adapters/net_http_adapter"

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
