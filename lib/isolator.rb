# frozen_string_literal: true

require "sniffer"
require "logger"

Dir["#{File.dirname(__FILE__)}/isolator/**/*.rb"].each { |f| require f }

module Isolator # :nodoc:
  class << self
    def start_analyze
      return unless block_given?

      analyzers.each(&:start)
      yield
      analyzers.each(&:infer!)
    end

    def analyzers
      [
        Isolator::Analyzers::HTTP.new
      ]
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
