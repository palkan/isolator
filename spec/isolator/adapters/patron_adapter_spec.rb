# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Patron do
  before { Isolator.enable! }

  shared_examples 'outgoing request' do |http_method|
    subject(:make_request) do
      sess = Patron::Session.new
      sess.base_url = 'http://example.com'
      sess.public_send(http_method, '/', {})
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
