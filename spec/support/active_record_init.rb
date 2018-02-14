# frozen_string_literal: true

require "active_record"
require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :name, :string
  end
end

class User < ActiveRecord::Base; end

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["LOG"]
