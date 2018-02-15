# frozen_string_literal: true

module Isolator
  class Railtie < ::Rails::Railtie # :nodoc:
    config.after_initialize do
      # Load adapters
      require "isolator/adapters"

      next unless Rails.env.test?

      if defined?(::ActiveRecord::TestFixtures)
        ::ActiveRecord::TestFixtures.prepend(
          Module.new do
            def setup_fixtures(*)
              super
              return unless run_in_transaction?

              open_count = ActiveRecord::Base.connection.open_transactions
              Isolator.transactions_threshold += open_count
            end

            def teardown_fixtures(*)
              if run_in_transaction?
                open_count = ActiveRecord::Base.connection.open_transactions
                Isolator.transactions_threshold -= open_count
              end
              super
            end
          end
        )
      end
    end
  end
end
