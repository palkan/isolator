# frozen_string_literal: true

require "active_job/railtie"
require "active_job"

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(IO::NULL)
