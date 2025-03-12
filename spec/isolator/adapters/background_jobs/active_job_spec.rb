# frozen_string_literal: true

require "spec_helper"

describe "ActiveJob adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#perform_now" do
    specify do
      expect { ActiveJobWorker.perform_now }.to_not raise_error
    end
  end

  describe "#perform_later" do
    specify do
      expect { ActiveJobWorker.perform_later("test") }.to raise_error(Isolator::BackgroundJobError, /ActiveJobWorker.+test/)
    end

    context "with enqueue_after_transaction_commit", :rails8 do
      after { ActiveJobWorker.enqueue_after_transaction_commit = false }

      context "configured to true" do
        before { ActiveJobWorker.enqueue_after_transaction_commit = true }

        specify do
          expect { ActiveJobWorker.perform_later("test") }.not_to raise_error
        end
      end

      context "configured to false" do
        before { ActiveJobWorker.enqueue_after_transaction_commit = false }

        specify do
          expect { ActiveJobWorker.perform_later("test") }.to raise_error(Isolator::BackgroundJobError, /ActiveJobWorker.+test/)
        end
      end
    end
  end
end
