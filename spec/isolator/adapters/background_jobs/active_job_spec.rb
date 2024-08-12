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
      after { reset_enqueue_after_transaction_commit }

      context "configured to :always" do
        before { set_enqueue_after_transaction_commit_to :always }

        specify do
          expect { ActiveJobWorker.perform_later("test") }.to_not raise_error
        end

        context "job class configured to :never" do
          before { ActiveJobWorker.enqueue_after_transaction_commit = :never }

          specify do
            expect(ActiveJob::Base.enqueue_after_transaction_commit).to eq :always
            expect { ActiveJobWorker.perform_later("test") }.to raise_error(Isolator::BackgroundJobError, /ActiveJobWorker.+test/)
          end
        end
      end

      context "configured to :default" do
        before { set_enqueue_after_transaction_commit_to :default }

        context "with queue_adapter enqueue_after_transaction_commit enabled" do
          before { ActiveJobWorker.enqueue_after_transaction_commit = :default }

          specify do
            expect { ActiveJobWorker.perform_later("test") }.to_not raise_error
          end
        end

        context "with queue_adapter enqueue_after_transaction_commit disabled" do
          before { ActiveJobWorker.enqueue_after_transaction_commit = :never }

          specify do
            expect { ActiveJobWorker.perform_later("test") }.to raise_error(Isolator::BackgroundJobError, /ActiveJobWorker.+test/)
          end
        end
      end

      context "configured to :never" do
        before { set_enqueue_after_transaction_commit_to :never }

        specify do
          expect { ActiveJobWorker.perform_later("test") }.to raise_error(Isolator::BackgroundJobError, /ActiveJobWorker.+test/)
        end
      end

      private

      def set_enqueue_after_transaction_commit_to(value)
        ActiveJob::Base.enqueue_after_transaction_commit = value
        ActiveJobWorker.enqueue_after_transaction_commit = value
      end

      def reset_enqueue_after_transaction_commit
        ActiveJob::Base.enqueue_after_transaction_commit = :never
        ActiveJobWorker.enqueue_after_transaction_commit = :never
      end
    end
  end
end
