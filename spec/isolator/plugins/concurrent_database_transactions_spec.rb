# frozen_string_literal: true

require "spec_helper"

describe "Concurrent multi database transactions" do
  around do |ex|
    was_disallowed = Isolator.config.disallow_per_thread_concurrent_transactions
    ex.run
    Isolator.config.disallow_per_thread_concurrent_transactions = was_disallowed
  end

  after do
    User.connection.reconnect!
    Post.connection.reconnect!
  end

  specify "when disabled" do
    Post.connection.begin_db_transaction
    expect(Isolator).to be_within_transaction

    User.connection.begin_db_transaction
    expect(Isolator).to be_within_transaction

    User.connection.commit_db_transaction
    expect(Isolator).to be_within_transaction

    Post.connection.commit_db_transaction
    expect(Isolator).to_not be_within_transaction
  end

  specify "when enabled" do
    Isolator.config.disallow_per_thread_concurrent_transactions = true

    Post.connection.begin_db_transaction
    expect(Isolator).to be_within_transaction

    expect do
      User.connection.begin_db_transaction
    end.to raise_error(Isolator::ConcurrentTransactionError)
  end

  # In-memory sqlite3 doesn't work well with multiple connections,
  # since we need to provide schema for each connection.
  # This is a regression test to make sure we don't treat other execution context transactions as ours.
  specify "when enabled and different connections to the same database", skip: DB_CONFIG[:adapter] != "postgresql" do
    Isolator.config.disallow_per_thread_concurrent_transactions = true

    break_one = Queue.new
    break_two = Queue.new

    t = Thread.new do
      User.transaction do
        User.create!(name: "test")
        break_one << true
        expect(Isolator).to be_within_transaction
        break_two.pop
      end

      expect(Isolator).to_not be_within_transaction
    end

    expect(Isolator).to_not be_within_transaction

    break_one.pop
    User.transaction do
      User.first
      expect(Isolator).to be_within_transaction
      break_two << true
    end

    t.join

    expect(Isolator).to_not be_within_transaction
  end
end
