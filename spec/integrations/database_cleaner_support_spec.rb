# frozen_string_literal: true

require "spec_helper"

describe "Database Cleaner tests" do
  context "Minitest" do
    specify "tests with exceptions" do
      output = run_minitest("database_cleaner", name: "test_raise_with_transaction")

      expect(output).to include("1 runs, 0 assertions, 0 failures, 1 errors")
    end

    specify "tests with exceptions" do
      output = run_minitest("database_cleaner", name: "test_no_transaction_no_raise")

      expect(output).to include("1 runs, 1 assertions, 0 failures, 0 errors")
    end
  end

  context "RSpec" do
    specify "tests with exceptions" do
      output = run_rspec("database_cleaner", tag: "offense")

      expect(output).to include("1 example, 1 failure")
    end

    specify "tests with exceptions" do
      output = run_rspec("database_cleaner", tag: "no_transaction")

      expect(output).to include("1 example, 0 failures")
    end
  end
end
