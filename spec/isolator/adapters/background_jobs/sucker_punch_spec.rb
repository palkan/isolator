# frozen_string_literal: true

require "spec_helper"

describe "SuckerPunch adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  let(:worker) { SuckerPunchWorker }

  describe "#perform_async" do
    specify do
      expect { worker.perform_async }.to raise_error(Isolator::BackgroundJobError)
    end
  end

  describe "#perform_in" do
    specify do
      expect { worker.perform_in(60) }.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
