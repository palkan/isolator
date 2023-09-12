# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord subtransactions detecting" do
  let(:ar_class) { User }

  before do
    allow(Isolator.config).to receive(:substransactions_depth_threshold).and_return(32)
  end

  def simulate_subtransaction(ar_class, depth)
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.transaction(requires_new: true) do
        ar_class.find_or_create_by(id: 1)
        simulate_subtransaction(ar_class, depth + 1) unless depth == Isolator.config.substransactions_depth_threshold
      end
    end
  end

  context "when subtransactions count starts equal to substransactions_depth_threshold" do
    it "raises exception if substransactions_depth_threshold == 32" do
      expect do
        simulate_subtransaction(ar_class, 0)
      end.to raise_error(Isolator::SubtransactionError)
    end
  end

  describe "Notifying about subtransactions" do
    context "when config.report_subtransactions = :log" do
      let(:logger) { instance_double("Logger") }

      before do
        Isolator.configure do |config|
          config.logger = logger
          config.raise_exceptions = false
          config.backtrace_filter = lambda do |_backtrace|
            %w[first/line/of/backtrace second/line/of/backtrace]
          end
          config.report_subtransactions = :log
        end
        allow(logger).to receive(:warn)
      end

      specify do
        simulate_subtransaction(ar_class, 0)

        expect(logger).to have_received(:warn).with(<<~MSG.chomp)
          [ISOLATOR EXCEPTION]
          #{Isolator::SubtransactionError::MESSAGE}
            ↳ first/line/of/backtrace
            ↳ second/line/of/backtrace
        MSG
      end
    end

    context "when config.report_subtransaction = :exception" do
      before do
        Isolator.configure do |config|
          config.report_subtransactions = :exception
        end
      end

      specify do
        expect { simulate_subtransaction(ar_class, 0) }.to raise_error(Isolator::SubtransactionError)
      end
    end

    context "when config.report_subtransaction = :notifier" do
      let(:uniform_notifier) { double(out_of_channel_notify: nil) }

      before do
        Isolator.configure do |config|
          config.raise_exceptions = false
          config.report_subtransactions = :notifier
        end
        allow(UniformNotifier).to receive(:active_notifiers) { [uniform_notifier] }
      end

      specify do
        simulate_subtransaction(ar_class, 0)
        expect(uniform_notifier).to have_received(:out_of_channel_notify).with(Isolator::SubtransactionError::MESSAGE)
      end
    end
  end
end

describe "ActiveRecord integration" do
  let(:ar_class) { User }

  describe ".transaction" do
    it do
      expect(Isolator).to_not be_within_transaction
      ar_class.transaction do
        ar_class.all.to_a
        expect(Isolator).to be_within_transaction
      end
      expect(Isolator).to_not be_within_transaction
    end

    context "subtransactions" do
      it do
        allow(Isolator).to receive_message_chain(:config, :substransactions_depth_threshold).and_return(32)

        expect(Isolator).not_to be_within_subtransaction
        expect(Isolator).not_to be_within_transaction

        ar_class.transaction do
          ar_class.transaction(requires_new: true) do
            ar_class.find_or_create_by(id: 1)
            expect(Isolator).to be_within_subtransaction
            expect(Isolator).to be_within_transaction
          end
        end

        expect(Isolator).not_to be_within_subtransaction
        expect(Isolator).not_to be_within_transaction
      end
    end
  end

  context "other transaction methods" do
    let(:connection) { ar_class.connection }

    describe "#execute" do
      specify do
        connection.execute("begin")
        expect(Isolator).to be_within_transaction

        connection.execute("commit")
        expect(Isolator).to_not be_within_transaction
      end
    end

    describe "#begin_db_transaction" do
      specify do
        connection.begin_db_transaction
        expect(Isolator).to be_within_transaction

        connection.commit_db_transaction
        expect(Isolator).to_not be_within_transaction
      end
    end
  end

  context "with multiple connections" do
    specify do
      Post.connection.begin_db_transaction
      expect(Isolator).to be_within_transaction

      User.connection.begin_db_transaction
      expect(Isolator).to be_within_transaction

      User.connection.commit_db_transaction
      expect(Isolator).to be_within_transaction

      Post.connection.commit_db_transaction
      expect(Isolator).to_not be_within_transaction
    end
  end
end
