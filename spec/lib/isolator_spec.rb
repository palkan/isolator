# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isolator do
  describe ".configure" do
    after { described_class.config.raise_exceptions = true }

    subject(:configure) do
      described_class.configure { |config| config.raise_exceptions = false }
    end

    specify do
      expect { configure }.to change { described_class.config.raise_exceptions }.to(false)
    end
  end
end
