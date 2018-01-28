# frozen_string_literal: true

require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  # Create schema here
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV["LOG"]
