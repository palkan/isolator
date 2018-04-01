# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "database_cleaner"

require_relative "../../../support/rails_app"
require "rspec/rails"

DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
  config.around do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end

describe "database_cleaner support" do
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
