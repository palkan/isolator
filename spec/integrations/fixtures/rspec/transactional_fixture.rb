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
end
