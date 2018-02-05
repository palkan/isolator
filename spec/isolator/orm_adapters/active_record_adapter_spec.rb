# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::Base do
  describe '.transaction' do
    context 'when making network request' do
      subject(:make_request) do
        described_class.transaction do
          HTTP.get('http://example.com')
        end
      end

      it { expect { make_request }.to raise_error(Isolator::NetworkRequestError) }
    end

    context 'when making request to redis' do
      subject(:access_redis) do
        described_class.transaction do
          Redis.new.get('key')
        end
      end

      it { expect { access_redis }.to raise_error(Isolator::RedisAccessError) }
    end
  end
end
