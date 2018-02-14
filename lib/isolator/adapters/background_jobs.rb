# frozen_string_literal: true

ActiveSupport.on_load(:active_job) do
  require "isolator/adapters/background_jobs/active_job"
end

require "isolator/adapters/background_jobs/sidekiq" if defined?(Sidekiq::Client)
