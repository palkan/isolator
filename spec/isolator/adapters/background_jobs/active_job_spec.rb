require "spec_helper"

RSpec.describe ActiveJob::Base do
  before { Isolator.enable! }

  describe '#perform_now' do
    specify do
      expect { described_class.perform_now }.to raise_error(Isolator::BackgroundJobError)
    end
  end

  describe '#perform_later' do
    specify do
      expect { described_class.perform_later }.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
