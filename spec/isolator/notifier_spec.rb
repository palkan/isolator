# frozen_string_literal: true

require "spec_helper"

describe Isolator::Notifier do
  describe "#call" do
    let(:exception) { Isolator::HTTPError.new("test exception") }

    let(:uniform_notifier) do
      double(out_of_channel_notify: nil)
    end

    before do
      allow(UniformNotifier).to receive(:active_notifiers) { [uniform_notifier] }
    end

    subject { described_class.new(exception).call }

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
          exception.message
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
        expect { subject }.to raise_error(Isolator::HTTPError)
        expect(uniform_notifier).to_not have_received(:out_of_channel_notify)
      end
    end

    context "when logging to a logger" do
      let(:logger) { instance_double("Logger") }

      before do
        Isolator.configure do |config|
          config.logger = logger
          config.backtrace_filter = lambda do |_backtrace|
            ["first/line/of/backtrace", "second/line/of/backtrace"]
          end
          config.raise_exceptions = false
        end
        allow(logger).to receive(:warn)
      end

      specify do
        subject

        expect(logger).to have_received(:warn).with(<<~MSG.chomp)
          [ISOLATOR EXCEPTION]
          test exception
            ↳ first/line/of/backtrace
            ↳ second/line/of/backtrace
        MSG
      end
    end
  end
end
