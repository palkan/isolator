# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::Base do
  after { expect(Isolator).to_not be_enabled }

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
      before { ActiveJob::Base.queue_adapter = :test }

      subject(:enqueue) do
        described_class.transaction do
          ActiveJobWorker.perform_later
        end
      end

      it { expect { enqueue }.to raise_error(Isolator::BackgroundJobError) }
    end
  end

  describe "#connection" do
    let(:connection) { described_class.connection }
    subject(:make_request) { HTTP.get("http://example.com") }

    describe "#execute" do
      specify do
        connection.execute("begin")
        expect { make_request }.to raise_error(Isolator::NetworkRequestError)

        connection.execute("commit")
        expect(Isolator).to_not be_enabled
      end
    end

    describe "#begin_db_transaction" do
      specify do
        connection.begin_db_transaction
        expect { make_request }.to raise_error(Isolator::NetworkRequestError)

        connection.commit_db_transaction
        expect(Isolator).to_not be_enabled
      end
    end
  end
end
