require "spec_helper"

RSpec.describe ActiveJob::Base do
  before do
    Isolator.enable!
    ActiveJob::Base.queue_adapter = :async
  end

  describe '#perform_now' do
    specify do
      expect { described_class.perform_now }.to raise_error(Isolator::BackgroundJobError)
    end
  end

  describe '#perform_later' do
    specify do
      expect { described_class.perform_later }.to raise_error(Isolator::BackgroundJobError)
    end

    context "when backend is db" do
      before { ActiveJob::Base.queue_adapter = :delayed_job }

      specify do
        expect { described_class.perform_later }.to_not raise_error
      end
    end
  end
end
