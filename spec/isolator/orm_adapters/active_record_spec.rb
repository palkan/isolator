# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord subtransactions detecting" do
  let(:ar_class) { User }

  context "when subtransactions count start equal to substransactions_depth_threshold" do
    it "raises error if substransactions_depth_threshold == 32" do
      allow(Isolator).to receive_message_chain(:config, :substransactions_depth_threshold).and_return(32)

      def simulate_subtransaction(ar_class, depth)
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.transaction(requires_new: true) do
            ar_class.find_or_create_by(id: 1)
            simulate_subtransaction(ar_class, depth + 1) unless depth == Isolator.config.substransactions_depth_threshold
          end
        end
      end

      expect do
        simulate_subtransaction(ar_class, 0)
      end.to raise_error(Isolator::SubtransactionError)
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
