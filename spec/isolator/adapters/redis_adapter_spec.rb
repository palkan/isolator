# frozen_string_literal: true

require "spec_helper"

RSpec.describe Redis do
  before { Isolator.enable! }

  subject(:client) { Redis.new }

  specify do
    expect { client.get("key") }.to raise_error(Isolator::RedisAccessError)
  end
end
