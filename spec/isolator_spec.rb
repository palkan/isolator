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

  describe ".within_subtransaction" do
    before do
      allow(Isolator).to receive_message_chain(:config, :substransactions_depth_threshold).and_return(32)
    end

    specify do
      expect(described_class).not_to be_within_transaction

      described_class.incr_subtransactions!
      expect(described_class).to be_within_subtransaction

      described_class.decr_subtransactions!
      expect(described_class).not_to be_within_subtransaction
    end
  end
end
