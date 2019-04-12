# frozen_string_literal: true

require "spec_helper"

describe "WebMock integration" do
  context "RSpec" do
    specify do
      output = run_rspec("webmock")

      expect(output).to include("2 examples, 1 failure")
      expect(output).to include("Isolator::HTTPError")
      expect(output).to include("GET http://www.example.com")
    end
  end
end
