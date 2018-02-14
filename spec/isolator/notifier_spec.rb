# frozen_string_literal: true

require "spec_helper"

describe Isolator::Notifier do
  describe "#call" do
    let(:exception_class) { Isolator::NetworkRequestError }

    let(:object) do
      double(isolator_exception: exception_class)
    end

    let(:uniform_notifier) do
      double(out_of_channel_notify: nil)
    end

    before do
      allow(UniformNotifier).to receive(:active_notifiers) { [uniform_notifier] }
    end

    subject { described_class.new(object).call }

    context "when sending notifications without raising exception " do
      before do
        Isolator.configure do |config|
          config.send_notifications = true
          config.raise_exceptions = false
        end
      end

      specify do
        subject

        expect(uniform_notifier).to have_received(
          :out_of_channel_notify
        ).with(
          exception_class.exception.message
        )
      end
    end

    context "when raising exceptions and not sending notifications" do
      before do
        Isolator.configure do |config|
          config.raise_exceptions = true
          config.send_notifications = false
        end
      end

      specify(aggregate_failures: true) do
        expect { subject }.to raise_error(Isolator::NetworkRequestError)
        expect(uniform_notifier).to_not have_received(:out_of_channel_notify)
      end

      context "when object has no isolator_exception" do
        let(:object) { double }

        it "raises UnsafeOperationError" do
          expect { subject }.to raise_error(Isolator::UnsafeOperationError)
        end
      end
    end
  end
end
