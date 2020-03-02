# frozen_string_literal: true

class SidekiqWorker
  include Sidekiq::Worker

  def perform
  end
end

Sidekiq::Extensions.enable_delay!

class SidekiqClass
  def self.do_later
  end
end
