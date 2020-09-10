# frozen_string_literal: true

require "active_record"
require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

require "fileutils"

ActiveRecord::Base.raise_in_transactional_callbacks = true unless
  ActiveRecord::VERSION::MAJOR >= 5

FILE_DB = File.join(__dir__, "../../tmp/testdb2")
FileUtils.mkdir_p(File.join(__dir__, "../../tmp/"))

unless File.file?(FILE_DB)
  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: FILE_DB)

  ActiveRecord::Schema.define do
    create_table :posts do |t|
      t.column :title, :string
    end
  end
end

class Post < ActiveRecord::Base
  establish_connection(adapter: "sqlite3", database: FILE_DB)
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :name, :string
  end
end

class User < ActiveRecord::Base; end

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]
