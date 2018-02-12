# temp
require 'pry'
#...

require 'net/http'

require 'spec_helper'

class User < ActiveRecord::Base
  def transaction_with_http_call
    transaction do
      update(name: 'updated #1')
      Net::HTTP.get('example.com', '/index.html')
    end
  end

  def transaction_without_http_call
    transaction do
      update(name: 'updated #2')
    end
  end
end

RSpec.describe ActiveRecord do
  let(:user) { User.create(name: 'test') }

  context 'when performing HTTP call within transaction' do
    it 'raises Isolator::Errors::HTTPError' do
      expect { user.transaction_with_http_call }.to raise_error(Isolator::Errors::HTTPError)
    end
  end

  context 'when not performing HTTP call within transaction' do
    it 'does not raise any errors' do
      expect { user.transaction_without_http_call }.not_to raise_error
    end
  end
end
