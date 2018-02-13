require 'spec_helper'
require 'net/http'

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

  context 'when raising errors enabled' do
    before do
      Isolator.configure do |isolator|
        isolator.raise_errors = true
      end
    end

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

  context 'when logger enabled' do
    before do
      Isolator.configure do |isolator|
        isolator.raise_errors = false
        isolator.logger = true
      end
    end

    context 'when performing HTTP call within transaction' do
      it 'writes to log' do
        expect_any_instance_of(Logger).to receive(:debug).with("Forbidden HTTP call within transaction was made!")

        user.transaction_with_http_call
      end
    end
  end
end
