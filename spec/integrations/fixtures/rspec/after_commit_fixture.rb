# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../../lib", __FILE__)

require_relative "../../../support/rails_app"

class User < ActiveRecord::Base
  attr_reader :commited

  after_commit :run_after_commit

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
  subject { User.create }

  it "doesn't raise in after_commit callback" do
    expect { subject }.not_to raise_error
    expect(subject.commited).to eq true
  end
end
