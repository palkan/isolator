require "spec_helper"

RSpec.describe Sidekiq do
  before { Isolator.enable! }
  let(:worker) { SidekiqWorker }

  describe '#perform_now' do
    specify do
      expect { worker.perform_async }.to raise_error(Isolator::BackgroundJobError)
    end
  end

  describe '#perform_later' do
    specify do
      expect { worker.perform_at(3.days.from_now) }.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
