# frozen_string_literal: true

require "rails"
require "action_controller/railtie"

require "isolator"

require_relative "./active_record_init"
require_relative "./action_mailer_init"
require_relative "./active_job_init"

class TestApp < Rails::Application
  secrets.secret_token = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.eager_load = true

  config.log_level = ENV["LOG"] ? :debug : :fatal
  config.logger = ENV["LOG"] ? Logger.new($stdout) : Logger.new("/dev/null")

  config.active_support.test_order = :random

  config.after_initialize do
    Rails.backtrace_cleaner.remove_silencers!
    Rails.backtrace_cleaner.remove_filters!
    spec_root = File.expand_path(File.join(__dir__, ".."))
    Rails.backtrace_cleaner.add_silencer { |line| !line.match?(/#{spec_root}\//) }
  end
end

require_relative "./workers/active_job_worker"

TestApp.initialize!
