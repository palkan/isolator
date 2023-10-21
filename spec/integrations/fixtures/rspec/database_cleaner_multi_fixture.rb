# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "database_cleaner"

require_relative "../../../support/rails_app"
require "rspec/rails"

require "active_job"
require "active_record"

require "uri"
require "net/http"

PRIMARY_DB = "primary.sqlite3"
SECONDARY_DB = "secondary.sqlite3"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: PRIMARY_DB)
ActiveRecord::Schema.define do
  create_table :animals do |t|
    t.string :name, null: false
  end
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: SECONDARY_DB)
ActiveRecord::Schema.define do
  create_table :pets do |t|
    t.string :nickname, null: false
  end
end

class DummyJob < ActiveJob::Base; end

class Animal < ActiveRecord::Base
  establish_connection(adapter: "sqlite3", database: PRIMARY_DB)

  after_commit { DummyJob.perform_later }
end

class Pet < ActiveRecord::Base
  establish_connection(adapter: "sqlite3", database: SECONDARY_DB)

  after_commit { Net::HTTP.get_response(URI("https://www.google.com/")) }
end

RSpec.configure do |config|
  DatabaseCleaner[:active_record, db: Pet].strategy = :transaction
  DatabaseCleaner[:active_record, db: Animal].strategy = :transaction

  config.before { DatabaseCleaner.start }

  config.after { DatabaseCleaner.clean }

  config.after(:suite) do
    File.delete(PRIMARY_DB)
    File.delete(SECONDARY_DB)
  end

  require "isolator"

  Isolator.configure { |isolator_config| isolator_config.raise_exceptions = true }
end

RSpec.describe "DatabaseCleaner with multiples databases" do
  it { Pet.create(nickname: "Spike") }
  it { Animal.create(name: "Dog") }
end
