# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::Base do
  describe ".transaction" do
    context "when making network request" do
      subject(:make_request) do
        described_class.transaction do
          HTTP.get("http://example.com")
        end
      end

      it { expect { make_request }.to raise_error(Isolator::NetworkRequestError) }
    end

    context "when enquing job" do
      subject(:enqueue) do
        described_class.transaction do
          ActiveJobWorker.perform_later
        end
      end

      it { expect { enqueue }.to raise_error(Isolator::BackgroundJobError) }
    end
  end
end
