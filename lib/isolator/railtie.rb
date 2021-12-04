# frozen_string_literal: true

module Isolator
  class Railtie < ::Rails::Railtie # :nodoc:
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

      Isolator.config.ignorer&.prepare
      Isolator.config.ignorer&.prepare(path: ".isolator_ignore.yml")

      next unless Rails.env.test?

      if defined?(::ActiveRecord::TestFixtures)
        ::ActiveRecord::TestFixtures.prepend(
          Module.new do
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
        )
      end
    end
  end
end
