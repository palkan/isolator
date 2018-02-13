require 'spec_helper'

class MyEmail < ActionMailer::Base
  default from: 'isolator@example.com'

  def hello
    mail(to: 'example.com', subject: 'test', body: 'test')
  end
end

class User < ActiveRecord::Base
  def transaction_with_mailer_call
    transaction do
      update(name: 'updated #1')
      MyEmail.hello.deliver
    end
  end

  def transaction_without_mailer_call
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

    context 'when sending emails within transaction' do
      it 'raises Isolator::Errors::ActionMailerUsage' do
        expect { user.transaction_with_mailer_call }.to raise_error(Isolator::Errors::ActionMailerUsage)
      end
    end

    context 'when not sending emails within transaction' do
      it 'does not raise any errors' do
        expect { user.transaction_without_mailer_call }.not_to raise_error
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

    context 'when sending emails within transaction' do
      it 'writes to log' do
        expect_any_instance_of(Logger).to receive(:debug).with("ActionMailer usage within transaction not allowed!")

        user.transaction_with_mailer_call
      end
    end
  end
end
