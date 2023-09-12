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

    context "when exception is raised within a transaction" do
      it do
        expect(Isolator).to_not be_within_transaction
        expect do
          expect do
            ar_class.transaction do
              ar_class.create!(name: "test")
              expect(Isolator).to be_within_transaction
              raise
            end
          end.to raise_error(RuntimeError)
        end.to change(ar_class, :count).by(0)
        expect(Isolator).to_not be_within_transaction
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
