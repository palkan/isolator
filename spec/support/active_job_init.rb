# frozen_string_literal: true

require "active_job/railtie"
require "active_job"

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(IO::NULL)
# disable transactional commits by default

begin
  ActiveJob::Base.include ActiveJob::EnqueueAfterTransactionCommit
  ActiveJob::Base.enqueue_after_transaction_commit = :never
rescue NameError
end
