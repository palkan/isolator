# frozen_string_literal: true

class ActiveJobWorker < ActiveJob::Base
  def perform(val = nil); end
end
