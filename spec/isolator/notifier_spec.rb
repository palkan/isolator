# frozen_string_literal: true

require "spec_helper"

describe Isolator::Notifier do
  describe "#call" do
    let(:exception) { Isolator::HTTPError.new("test exception") }

    let(:uniform_notifier) do
      double(out_of_channel_notify: nil)
    end

    subject { described_class.new(exception).call }

    context "when raising exceptions and not sending notifications" do
      before do
        Isolator.configure do |config|
          config.raise_exceptions = true
          config.send_notifications = false
        end
      end

      specify(aggregate_failures: true) do
        expect { subject }.to raise_error(Isolator::HTTPError)
        expect(uniform_notifier).to_not have_received(:out_of_channel_notify)
      end
    end
  end
end
