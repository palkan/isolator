# frozen_string_literal: true

module Isolator
  class Railtie < ::Rails::Railtie # :nodoc:
    module TestFixtures
      def setup_fixtures(*)
        super
        return unless run_in_transaction?

        Isolator.incr_thresholds!
      end

      def teardown_fixtures(*)
        if run_in_transaction?
          Isolator.decr_thresholds!
        end
        super
      end
    end

    initializer "isolator.backtrace_cleaner" do
      ActiveSupport.on_load(:active_record) do
        Isolator.backtrace_cleaner = lambda do |locations|
          ::Rails.backtrace_cleaner.clean(locations)
        end
      end
    end

    config.after_initialize do
      # Forec load adapters after application initialization
      # (when all deps are likely to be loaded).
      load File.join(__dir__, "adapters.rb")

      # Try to load Rails base classes to trigger their load hooks
      begin
        ::ActionMailer::Base
      rescue NameError
      end

      begin
        ::ActiveJob::Base
      rescue NameError
      end

      Isolator.config.ignorer&.prepare(path: ".isolator_todo.yml")
      Isolator.config.ignorer&.prepare(path: ".isolator_ignore.yml")

      next unless Rails.env.test?

      ActiveSupport.on_load(:active_record_fixtures) do
        ::ActiveRecord::TestFixtures.prepend(TestFixtures)
      end

      # Rails <7.1 doesn't support this load hook, so we we fallback to the prev behaviour
      if (ActiveRecord::VERSION::MAJOR < 7 || ActiveRecord::VERSION::MINOR < 1) && defined?(::ActiveRecord::TestFixtures)
        ::ActiveRecord::TestFixtures.prepend(TestFixtures)
      end
    end
  end
end
