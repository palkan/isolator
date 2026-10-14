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

  describe ".all_transactions" do
    it "drops a connection once its transactions are closed" do
      described_class.incr_transactions!
      described_class.decr_transactions!

      expect(described_class.all_transactions).to be_empty
    end
  end

  describe ".incr_transactions!" do
    it "rejects an unknown kind" do
      expect { described_class.incr_transactions!(kind: :raw) }
        .to raise_error(ArgumentError, /Unknown transaction kind: :raw/)

      expect(described_class.all_transactions).to be_empty
    end
  end
end
