# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isolator::Notifier do
  describe "#call" do
    let(:object) { double }

    subject(:notifier) { described_class.new(object) }

    context "when sending notifications without raising exception " do
      before do
        allow(notifier).to receive(:send_notifications?).and_return(true)
        allow(notifier).to receive(:raise_exceptions?).and_return(false)
      end

      specify do
        expect(UniformNotifier).to receive(:active_notifiers).and_return []

        notifier.call
      end
    end

    context "when raising exceptions" do
      let(:object) { double(isolator_exception: Isolator::NetworkRequestError) }

      specify do
        expect { notifier.call }.to raise_error(Isolator::NetworkRequestError)
      end

      context "when object has no isolator_exception" do
        specify do
          expect { notifier.call }.to raise_error(Isolator::UnsafeOperationError)
        end
      end
    end
  end
end
