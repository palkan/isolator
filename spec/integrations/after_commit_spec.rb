# frozen_string_literal: true

require "spec_helper"

describe "after_commit integration" do
  context "RSpec" do
    specify do
      output = run_rspec("after_commit")

      expect(output).to include("1 example, 0 failures")
    end
  end
end
