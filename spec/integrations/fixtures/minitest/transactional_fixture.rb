# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require_relative "../../../support/rails_app"
require "rails/test_help"

class IsolatorTransactionalTest < ActiveSupport::TestCase
  self.use_transactional_tests = true if respond_to?(:use_transactional_tests)
  self.use_transactional_fixtures = true if respond_to?(:use_transactional_fixtures)

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

class IsolatorNonTransactionalTest < ActiveSupport::TestCase
  self.use_transactional_tests = false if respond_to?(:use_transactional_tests)
  self.use_transactional_fixtures = false if respond_to?(:use_transactional_fixtures)

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
