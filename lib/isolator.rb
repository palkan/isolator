# frozen_string_literal: true
require 'pry'
require "anyway"
require "uniform_notifier"

require "isolator/version"
require "isolator/adapter_builder"
require "isolator/notifier"
require "isolator/errors"
require "isolator/config"

require "isolator/orm_adapters/active_record_adapter" if defined?(ActiveRecord::Base)

require "isolator/adapters/http/ethon_adapter" if defined?(::Ethon::Easy)
require "isolator/adapters/http/patron_adapter" if defined?(::Patron::Session)
require "isolator/adapters/http/httpclient_adapter" if defined?(::HTTPClient)
require "isolator/adapters/http/http_adapter" if defined?(::HTTP::Client)
require "isolator/adapters/http/net_http_adapter"
require "isolator/adapters/background_jobs/active_job" if defined?(ActiveJob::Base)

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
