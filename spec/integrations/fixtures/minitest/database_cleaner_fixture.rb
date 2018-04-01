# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "database_cleaner"

require_relative "../../../support/rails_app"
require "rails/test_help"

DatabaseCleaner.strategy = :transaction

class IsolatorDatabaseCleanerTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

  def test_no_transaction_no_raise
    ActiveJobWorker.perform_later
    assert true
  end

  def test_raise_with_transaction
    User.transaction do
      ActiveJobWorker.perform_later
    end

    assert true
  end
end
