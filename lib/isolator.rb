# frozen_string_literal: true

require "sniffer"

Dir["#{File.dirname(__FILE__)}/isolator/**/*.rb"].each { |f| require f }

module Isolator # :nodoc:
  def self.start_analyze
    return unless block_given?

    analyzers.each(&:start)
    yield
    analyzers.each(&:infer!)
  end

  def self.analyzers
    [
      Isolator::Analyzers::HTTP.new
    ]
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(self.configuration)
  end
end
