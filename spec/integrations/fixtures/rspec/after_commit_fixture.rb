# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require_relative "../../../support/rails_app"

require "after_commit_everywhere"

class User < ActiveRecord::Base
  attr_reader :commited

  after_commit :run_after_commit, on: :create

  def run_after_commit
    ActiveJobWorker.perform_later
    @commited = true
  end
end

require "rspec/rails"

require "test_after_commit" unless ActiveRecord::VERSION::MAJOR >= 5

require "isolator/adapters/after_commit"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

describe "use_transactional_tests=true" do
  include AfterCommitEverywhere

  subject { User.create!(name: "test") }

  it "doesn't raise in after_commit callback" do
    expect { subject }.not_to raise_error
    expect(subject.commited).to eq true
  end

  it "doesn't raise when after_commit is called within a nested transaction" do
    expect do
      User.create!(name: "no_transaction")
      User.transaction(requires_new: true) do
        User.create!(name: "requires_new")
        after_commit do
          ActiveJobWorker.perform_later
        end
      end
    end.not_to raise_error
  end
end
