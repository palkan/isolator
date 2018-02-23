# frozen_string_literal: true

class ResqueWorker
  @queue = :dummy_queue

  def self.perform; end
end
