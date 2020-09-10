# frozen_string_literal: true

require "spec_helper"

describe "Rails transactional tests" do
  context "Minitest" do
    specify "tests with exceptions" do
      output = run_minitest("transactional", name: "test_raise_with_transaction")

      expect(output).to include("2 runs, 0 assertions, 0 failures, 2 errors")
    end

    specify "tests with exceptions" do
      output = run_minitest("transactional", name: "test_no_transaction_no_raise")

      expect(output).to include("2 runs, 2 assertions, 0 failures, 0 errors")
    end
  end

  context "RSpec" do
    specify "tests with exceptions" do
      output = run_rspec("transactional", tag: "offense")

      expect(output).to include("1 example, 1 failure")
    end

    specify "tests with exceptions" do
      output = run_rspec("transactional", tag: "no_transaction")

      expect(output).to include("1 example, 0 failures")
    end

    specify "tests with group-level transactions" do
      output = run_rspec("transactional", tag: "nested")

      expect(output).to include("2 examples, 1 failure")
    end

    specify "multiple databases" do
      output = run_rspec("transactional", tag: "multi")

      expect(output).to include("1 example, 0 failures")
    end
  end
end
