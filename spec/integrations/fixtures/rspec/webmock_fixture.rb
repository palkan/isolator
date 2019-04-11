# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../../../lib", __dir__)

require "webmock"
require_relative "../../../support/rails_app"

require "net/http"
require "rspec/rails"
require "webmock/rspec"

require "isolator"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

describe "HTTP calls with WebMock" do
  before { stub_request(:any, "www.example.com") }

  subject { Net::HTTP.get("www.example.com", "/") }

  it "doesn't raise when no transaction", :no_transaction do
    expect { subject }.not_to raise_error
  end

  it "raises with transaction", :offense do
    User.transaction do
      User.first
      subject
    end
    expect(true).to eq true
  end
end
