# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isolator::ThreadStateProxy do
  subject { described_class.new("isolator_") }

  after { Thread.current["isolator_key"] = nil }

  describe "#[]" do
    before { Thread.current["isolator_key"] = "isolator-value" }

    it "fetches value indexed by prefixed key" do
      expect(subject["key"]).to eq("isolator-value")
    end
  end

  describe "#[]=" do
    it "stores value indexed by prefixed key" do
      subject["key"] = "isolator-value"

      expect(Thread.current["isolator_key"]).to eq("isolator-value")
    end
  end
end
