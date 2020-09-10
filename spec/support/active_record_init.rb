# frozen_string_literal: true

require "active_record"
require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.raise_in_transactional_callbacks = true unless
  ActiveRecord::VERSION::MAJOR >= 5
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :name, :string
  end
end

class User < ActiveRecord::Base; end

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]
