# frozen_string_literal: true

require "spec_helper"

describe Isolator do
  describe ".within_transaction" do
    specify do
      expect(described_class).not_to be_within_transaction

      described_class.incr_transactions!
      expect(described_class).to be_within_transaction

      described_class.decr_transactions!
      expect(described_class).not_to be_within_transaction
    end
  end
end
