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
    before(:all) do
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
    end

    after(:all) do
      ActiveRecord::Base.connection.rollback_transaction
    end

    it "doesn't raise when no transaction within example" do
      expect { ActiveJobWorker.perform_later }.not_to raise_error
    end

    it "raises with transaction" do
      User.transaction do
        ActiveJobWorker.perform_later
      end
      expect(true).to eq true
    end
  end

  it "doesn't raise when no transaction", :no_transaction do
    expect { ActiveJobWorker.perform_later }.not_to raise_error
  end

  it "raises with transaction", :offense do
    User.transaction do
      ActiveJobWorker.perform_later
    end
    expect(true).to eq true
  end
end
