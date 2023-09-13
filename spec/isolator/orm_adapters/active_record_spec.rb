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

    # Run this test only on PG, so we can terminate the connection from the outside
    context "when connection is terminated while being within a transaction", skip: DB_CONFIG[:adapter] != "postgresql" do
      it do
        expect(Isolator).to_not be_within_transaction

        expect do
          conn_id_q = Queue.new
          cont = Queue.new

          t = Thread.new do
            expect do
              User.transaction do
                User.create!(name: "test")
                conn_id_q << User.connection.raw_connection.backend_pid
                expect(Isolator).to be_within_transaction
                cont.pop
              end
            end.to raise_error(ActiveRecord::StatementInvalid)

            expect(Isolator).to_not be_within_transaction
          end

          conn_id = conn_id_q.pop

          User.connection.execute("select pg_terminate_backend(#{conn_id})")

          cont << true

          t.join
        end.not_to change(User, :count)

        expect(Isolator).to_not be_within_transaction
      end
    end

    context "when failed to commit", skip: !(ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1) do
      it do
        expect(Isolator).to_not be_within_transaction

        expect do
          # Uses the seconds database here with the persistent sqlite, so we do not lose schema
          Post.transaction do
            Post.create!(title: "test")
            expect(Isolator).to be_within_transaction
            allow(Post.connection).to receive(:commit_db_transaction).and_raise("Failed to commit")
            allow(Post.connection).to receive(:rollback_db_transaction) {
              raise "Failed to rollback"
            }
          end
        end.to raise_error(/failed to rollback/i)

        expect(Isolator).to_not be_within_transaction
      end
    end

    context "when rolling back a restarting savepoint transaction", skip: !(ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1) do
      specify do
        expect(Isolator).to_not be_within_transaction

        begin
          # RealTransaction (begin..rollback)
          ar_class.transaction do
            ar_class.first
            # Savepoint Transaction (savepoint..rollback)
            ar_class.transaction(requires_new: true) do
              # ResetParentTransaction (rollback to outer savepoint)
              ar_class.transaction(requires_new: true) do
                ar_class.first
                expect(Isolator).to be_within_transaction
                raise ActiveRecord::Rollback
              end

              ar_class.first
            end
            ar_class.first
          ensure
            expect(Isolator).to be_within_transaction
          end
        rescue
        end

        expect(Isolator).to_not be_within_transaction
      end
    end

    context "with lazy and non-lazy nested transactions" do
      specify do
        expect(Isolator).to_not be_within_transaction

        begin
          ar_class.connection.begin_transaction(joinable: false)
          ar_class.connection.begin_transaction(joinable: false, _lazy: false)

          ar_class.transaction(requires_new: true) do
            ar_class.first
            expect(Isolator).to be_within_transaction
          end

          expect(Isolator).to be_within_transaction
        ensure
          ar_class.connection.rollback_transaction
          ar_class.connection.rollback_transaction
        end

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
