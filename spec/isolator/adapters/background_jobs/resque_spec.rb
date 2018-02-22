# frozen_string_literal: true

require "spec_helper"

describe "Resque adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#enqueue" do
    specify do
      expect { Resque.enqueue(ResqueWorker) }.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
