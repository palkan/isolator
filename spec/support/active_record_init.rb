# frozen_string_literal: true

require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :delayed_jobs, force: true do |table|
    table.integer :priority, default: 0, null: false
    table.integer :attempts, default: 0, null: false
    table.text :handler,                 null: false
    table.text :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.datetime :failed_at
    table.string :locked_by
    table.string :queue
    table.timestamps null: true
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["LOG"]
