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
  end
end
