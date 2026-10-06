# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require_relative "../../../support/rails_app"
require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

describe "use_transactional_tests=true" do
  context "nested transactions", :nested do
    it "doesn't raise when no transaction within example" do
      expect do
        User.first
        ActiveJobWorker.perform_later
      end.not_to raise_error
    end

    it "raises with transaction" do
      User.transaction do
        User.first
        ActiveJobWorker.perform_later
      end
      expect(true).to eq true
    end
  end

  it "doesn't raise when no transaction", :no_transaction do
    expect do
      User.first
      ActiveJobWorker.perform_later
    end.not_to raise_error
  end

  it "raises with transaction", :offense do
    User.transaction do
      User.first
      ActiveJobWorker.perform_later
    end
    expect(true).to eq true
  end

  context "with multiple connections", :multi do
    before { @conn = ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:" }

    it "doesn't raise when new connection is initialized" do
      ActiveJobWorker.perform_later
      expect(true).to eq true
    end

    context "with before(:all)" do
      before(:all) do
        Isolator.transactions_threshold += 1
        ::ActiveRecord::Base.connection.begin_transaction(joinable: false)
      end

      after(:all) do
        Isolator.transactions_threshold -= 1
        ::ActiveRecord::Base.connection.rollback_transaction unless ::ActiveRecord::Base.connection.open_transactions.zero?
      end

      it "doesn't raise when new connection is initialized" do
        expect { ActiveJobWorker.perform_later }.not_to raise_error
      end
    end
  end

  # The examples run in the order they're defined
  context "when a connection reset drops a test's transaction", :reset do
    it "resets the connection" do
      # Uses the second database here with the persistent sqlite, so we do not lose schema
      Post.first
      Post.connection.reconnect!(restore_transactions: true)
    end

    it "doesn't raise in the next test" do
      Post.first

      expect { ActiveJobWorker.perform_later }.not_to raise_error
    end
  end

  context "with a server thread sharing the test's connection, like in system tests", :server_thread do
    def on_server_thread(&block)
      Thread.new do
        Thread.current.report_on_exception = false
        # Holds on to the connection, like a request does
        ActiveRecord::Base.respond_to?(:lease_connection) ? ActiveRecord::Base.lease_connection : ActiveRecord::Base.connection
        block.call
      end.value
    end

    it "doesn't raise outside of a transaction" do
      expect { on_server_thread { ActiveJobWorker.perform_later } }.not_to raise_error
    end

    it "raises within a transaction" do
      expect do
        on_server_thread do
          User.transaction do
            User.first
            ActiveJobWorker.perform_later
          end
        end
      end.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
