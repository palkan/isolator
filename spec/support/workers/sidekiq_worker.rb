# frozen_string_literal: true

class SidekiqWorker
  include Sidekiq::Worker

  def perform; end
end
