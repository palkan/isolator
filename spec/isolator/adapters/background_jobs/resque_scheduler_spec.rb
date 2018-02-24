# frozen_string_literal: true

require "spec_helper"

describe "Resque scheduler adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#enqueue_at" do
    specify do
      expect { Resque.enqueue_at(5.days.from_now, ResqueWorker) }.to(
        raise_error(Isolator::BackgroundJobError)
      )
    end
  end

  describe "#enqueue_in" do
    specify do
      expect { Resque.enqueue_in(1.minute, ResqueWorker) }.to(
        raise_error(Isolator::BackgroundJobError)
      )
    end
  end
end
