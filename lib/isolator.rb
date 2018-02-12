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
end
