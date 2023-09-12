# frozen_string_literal: true

require "active_record"
require "activerecord-jdbc-adapter" if defined? JRUBY_VERSION
require "activerecord-jdbcsqlite3-adapter" if defined? JRUBY_VERSION

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]

DB_CONFIG =
  if ENV["DB"] == "postgres" || ENV["DB"] == "mysql"
    require "active_record/database_configurations"
    url = ENV.fetch("DATABASE_URL") do
      case ENV["DB"]
      when "postgres"
        ENV.fetch("POSTGRES_URL")
      when "mysql"
        ENV.fetch("MYSQL_URL")
      end
    end

    ENV["DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL"] = "true"

    config = ActiveRecord::DatabaseConfigurations::UrlConfig.new(
      "test",
      "primary",
      url,
      {"database" => ENV.fetch("DB_NAME", "isolator_test")}
    )
    config.respond_to?(:configuration_hash) ? config.configuration_hash : config.config
  else
    # Make sure we don't have a DATABASE_URL set (it can be used by libs, e.g., database_cleaner)
    ENV.delete("DATABASE_URL") if ENV["DATABASE_URL"]
    {adapter: "sqlite3", database: ":memory:"}
  end

# Setting up a second database for testing multi-db support
# NOTE: We start with the second one to create its schema and then establish the primary connection
require "fileutils"

FILE_DB = File.join(__dir__, "../../tmp/testdb2")
FileUtils.mkdir_p(File.join(__dir__, "../../tmp/"))
DB_CONFIG_POSTS = {adapter: "sqlite3", database: FILE_DB}

FileUtils.rm_f(FILE_DB) if File.exist?(FILE_DB)

ActiveRecord::Base.establish_connection(**DB_CONFIG_POSTS)

ActiveRecord::Schema.define do
  create_table :posts, if_not_exists: true do |t|
    t.column :title, :string
  end
end

class Post < ActiveRecord::Base
  establish_connection(**DB_CONFIG_POSTS)
end

$stdout.puts "⚙️ Using #{DB_CONFIG[:adapter]} adapter for a primary database"

ActiveRecord::Base.establish_connection(**DB_CONFIG)

ActiveRecord::Schema.define do
  create_table :users, if_not_exists: true do |t|
    t.column :name, :string
  end
end

class User < ActiveRecord::Base; end
