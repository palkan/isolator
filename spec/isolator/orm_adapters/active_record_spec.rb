# frozen_string_literal: true

require "spec_helper"
require "after_commit_everywhere"

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

    context "when rolling back a lazy nested transaction", skip: !(ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1) do
      specify do
        record = ar_class.create!(name: "test")

        expect(Isolator).not_to receive(:warn).with("Trying to finalize an untracked transaction")

        ar_class.connection.transaction do
          ar_class.connection.transaction(requires_new: true) do
            record.touch
            raise ActiveRecord::Rollback
          end

          record.touch
        end

        expect(Isolator).to_not be_within_transaction
      end
    end

    context "when Active Record emits a transaction finish that was not tracked", skip: !(ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1) do
      specify do
        subscriber = Isolator::ActiveSupportTransactionSubscriber::Subscriber.new

        expect(Isolator).not_to receive(:warn).with("Trying to finalize an untracked transaction")

        subscriber.finish("transaction.active_record", "transaction-id", {connection: ar_class.connection})

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

    context "with ActiveRecord's transaction depth", skip: !defined?(Isolator::ActiveSupportTransactionSubscriber) do
      it "honors thresholds for a non-joinable wrapper transaction, like transactional tests" do
        Isolator.incr_thresholds!
        ar_class.connection.begin_transaction(joinable: false, _lazy: false)
        ar_class.first

        expect(Isolator).to_not be_within_transaction

        ar_class.transaction do
          ar_class.first
          expect(Isolator).to be_within_transaction
        end

        expect(Isolator).to_not be_within_transaction
      ensure
        ar_class.connection.rollback_transaction
        Isolator.decr_thresholds!
      end

      it "honors thresholds for a joinable wrapper transaction" do
        Isolator.transactions_threshold += 1
        ar_class.connection.begin_transaction
        ar_class.first

        expect(Isolator).to_not be_within_transaction

        ar_class.transaction(requires_new: true) do
          ar_class.first
          expect(Isolator).to be_within_transaction
        end
      ensure
        ar_class.connection.rollback_transaction
        Isolator.transactions_threshold -= 1
      end

      it "detects a non-joinable transaction" do
        ar_class.transaction(joinable: false) do
          ar_class.first
          expect(Isolator).to be_within_transaction
        end
      end

      it "detects a transaction before its first query" do
        ar_class.transaction do
          expect(Isolator).to be_within_transaction
        end
      end

      it "is not within a transaction inside after_commit callbacks" do
        within_after_commit = nil

        ar_class.transaction do
          ar_class.first
          AfterCommitEverywhere.after_commit { within_after_commit = Isolator.within_transaction? }
        end

        expect(within_after_commit).to eq(false)
      end

      # Rails drops a dirty transaction without emitting its finish event when it reconnects,
      # which used to leave the counted transaction open forever (https://github.com/palkan/isolator/issues/83)
      it "is not within a transaction after a reconnect drops the open transaction" do
        # Uses the second database here with the persistent sqlite, so we do not lose schema
        Post.connection.begin_transaction
        Post.first

        Post.connection.reconnect!(restore_transactions: true)

        expect(Post.connection.open_transactions).to eq(0)
        expect(Isolator).to_not be_within_transaction
      end

      it "is not within a transaction in the next wrapper after a reconnect drops the previous one" do
        Isolator.incr_thresholds!

        # A transactional test whose connection gets reset
        Post.connection.begin_transaction(joinable: false, _lazy: false)
        Post.first
        Post.connection.reconnect!(restore_transactions: true)

        # The next transactional test
        Post.connection.begin_transaction(joinable: false, _lazy: false)
        Post.first

        expect(Isolator).to_not be_within_transaction
      ensure
        Post.connection.rollback_transaction while Post.connection.open_transactions.positive?
        Isolator.decr_thresholds!
      end

      context "with a connection shared across threads, like the server threads in system tests",
        skip: !ActiveRecord::ConnectionAdapters::ConnectionPool.method_defined?(:pin_connection!) do
        shared_examples "a shared connection" do
          around do |example|
            register_wrapper.call
            pool = ar_class.connection_pool
            pool.pin_connection!(true)
            fixture_transaction = pool.lease_connection.open_transactions.zero?
            pool.lease_connection.begin_transaction(joinable: false, _lazy: false) if fixture_transaction
            example.run
          ensure
            pool.lease_connection.rollback_transaction if fixture_transaction
            pool.unpin_connection!
            unregister_wrapper.call
          end

          # A server thread holds on to its connection while handling a request
          def within_transaction_on_server_thread(&block)
            Thread.new do
              ar_class.lease_connection
              block&.call
              Isolator.within_transaction?
            ensure
              ar_class.connection_pool.release_connection
            end.value
          end

          it "honors the wrapper's threshold" do
            expect(within_transaction_on_server_thread).to eq(false)
          end

          it "detects a transaction opened on the server thread" do
            within = nil

            within_transaction_on_server_thread do
              ar_class.transaction do
                ar_class.first
                within = Isolator.within_transaction?
              end
            end

            expect(within).to eq(true)
          end
        end

        context "when the wrapper raises the default threshold, like transactional tests" do
          let(:register_wrapper) { -> { Isolator.incr_thresholds! } }
          let(:unregister_wrapper) { -> { Isolator.decr_thresholds! } }

          include_examples "a shared connection"
        end

        context "when the wrapper raises the connection's threshold, like database_cleaner" do
          let(:register_wrapper) { -> { Isolator.transactions_threshold += 1 } }
          let(:unregister_wrapper) { -> { Isolator.transactions_threshold -= 1 } }

          include_examples "a shared connection"
        end
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

    # SQLite raises on a nested BEGIN, which stands in for a BEGIN failing on a lost connection
    context "when BEGIN fails", skip: DB_CONFIG[:adapter] != "sqlite3" do
      # Start from a fresh connection: depending on the previous example, Rails may otherwise replace
      # the connection when BEGIN fails, taking this example's own raw transaction with it
      before { Post.connection.reconnect! }

      after do
        Post.connection.execute("ROLLBACK") if Post.connection.raw_connection.transaction_active?
      end

      it "doesn't count the failed raw BEGIN" do
        Post.connection.execute("BEGIN")
        expect { Post.connection.execute("BEGIN") }.to raise_error(ActiveRecord::StatementInvalid)
        Post.connection.execute("ROLLBACK")

        expect(Isolator).to_not be_within_transaction
      end

      it "doesn't count a transaction ActiveRecord failed to open" do
        Post.connection.execute("BEGIN")
        expect { Post.transaction { Post.first } }.to raise_error(ActiveRecord::StatementInvalid)
        Post.connection.execute("ROLLBACK") if Post.connection.raw_connection.transaction_active?

        expect(Isolator).to_not be_within_transaction
      end
    end

    it "doesn't count a raw transaction on a connection that was discarded", skip: !defined?(Isolator::ActiveSupportTransactionSubscriber) do
      discarded_connection = Post.connection
      discarded_connection.execute("BEGIN")
      expect(Isolator).to be_within_transaction

      Post.connection_pool.remove(discarded_connection)

      expect(Post.connection).not_to equal(discarded_connection)
      expect(Isolator).to_not be_within_transaction
    ensure
      discarded_connection.execute("ROLLBACK") if discarded_connection.raw_connection.transaction_active?
      discarded_connection.disconnect!
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
