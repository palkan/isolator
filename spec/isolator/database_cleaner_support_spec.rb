# frozen_string_literal: true

require "spec_helper"
require "database_cleaner/active_record"
require "isolator/database_cleaner_support"

describe "database_cleaner support" do
  # Uses the second database here with the persistent sqlite, so replacing the connection doesn't lose the schema
  let(:strategy) { DatabaseCleaner::ActiveRecord::Transaction.new.tap { |strategy| strategy.db = Post } }

  def current_connection
    Post.respond_to?(:lease_connection) ? Post.lease_connection : Post.connection
  end

  it "restores the threshold of the connection it started on, when the connection is replaced in between" do
    started_connection = current_connection
    threshold = Isolator.transactions_threshold(started_connection.object_id)

    strategy.start
    expect(Isolator.transactions_threshold(started_connection.object_id)).to eq(threshold + 1)

    # E.g., the connection gets reaped or reconnected mid-test
    Post.connection_pool.remove(started_connection)
    replacement_connection = current_connection
    expect(replacement_connection).not_to equal(started_connection)

    strategy.clean

    expect(Isolator.transactions_threshold(started_connection.object_id)).to eq(threshold)
    expect(Isolator.transactions_threshold(replacement_connection.object_id)).to eq(threshold)
  ensure
    started_connection.rollback_transaction while started_connection.open_transactions.positive?
    started_connection.disconnect!
    [started_connection, replacement_connection].compact.each do |connection|
      Isolator.set_connection_threshold(threshold, connection.object_id)
    end
  end
end
