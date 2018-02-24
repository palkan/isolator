# frozen_string_literal: true

if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_job) do
    require "isolator/adapters/background_jobs/active_job"
  end
end

require "isolator/adapters/background_jobs/sidekiq" if defined?(Sidekiq::Client)
require "isolator/adapters/background_jobs/resque" if defined?(Resque)
require "isolator/adapters/background_jobs/resque_scheduler" if defined?(Resque::Scheduler)
require "isolator/adapters/background_jobs/sucker_punch" if defined?(SuckerPunch::Queue)
