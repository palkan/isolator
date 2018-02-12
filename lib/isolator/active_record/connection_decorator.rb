# frozen_string_literal: true

module Isolator
  module ActiveRecord
    class ConnectionDecorator < BasicObject
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def execute(sql, name = nil)
        ::Isolator.enable! if /^begin/i === sql
        result = connection.execute(sql, name)
        ::Isolator.disable! if /(commit|rollback)$/i === sql
        result
      end

      def begin_isolated_db_transaction(isolation)
        ::Isolator.enable!
        connection.begin_isolated_db_transaction(isolation)
      end

      def begin_db_transaction
        ::Isolator.enable!
        connection.begin_db_transaction
      end

      def commit_db_transaction
        ::Isolator.disable!
        connection.commit_db_transaction
      end

      def method_missing(method, *args, &block)
        connection.send(method, *args, &block)
      end
    end
  end
end
