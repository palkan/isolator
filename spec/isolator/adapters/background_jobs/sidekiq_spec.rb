# frozen_string_literal: true

require "spec_helper"

describe "Sidekiq adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  let(:worker) { SidekiqWorker }

  describe "#perform_now" do
    specify do
      expect { worker.perform_async }.to raise_error(Isolator::BackgroundJobError)
    end
  end

  describe "#perform_later" do
    specify do
      expect { worker.perform_at(3.days.from_now) }.to raise_error(Isolator::BackgroundJobError, /SidekiqWorker/)
    end
  end
end
