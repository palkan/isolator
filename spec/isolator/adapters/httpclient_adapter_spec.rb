# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HTTPClient do
  before { Isolator.enable! }

  shared_examples 'outgoing request' do |http_method|
    subject(:make_request) do
      client = HTTPClient.new
      client.public_send(http_method, URI('http://example.com'))
    end

    it { expect { make_request }.to raise_exception(Isolator::NetworkRequestError) }
  end

  describe '.get' do
    it_behaves_like 'outgoing request', 'get'
  end

  describe '.put' do
    it_behaves_like 'outgoing request', 'put'
  end

  describe '.post' do
    it_behaves_like 'outgoing request', 'post'
  end

  describe '.delete' do
    it_behaves_like 'outgoing request', 'delete'
  end
end
