# frozen_string_literal: true

require "spec_helper"

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
end
