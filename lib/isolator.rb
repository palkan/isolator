# frozen_string_literal: true

require "sniffer"
require "logger"

Dir["#{File.dirname(__FILE__)}/isolator/**/*.rb"].each { |f| require f }

module Isolator # :nodoc:
  class << self
    def start_analyze
      analyzers.values.each(&:start)
      result = yield
      analyzers.values.each(&:infer!)
      result
    end
    
    def analyzers
      {
        http: Isolator::Analyzers::HTTP.new,
        action_mailer: Isolator::Analyzers::ActionMailer.new
      }
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def logger
      Logger.new(STDOUT)
    end
  end
end
