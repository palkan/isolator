# frozen_string_literal: true

require "spec_helper"

describe "Mailer adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#deliver_now" do
    specify do
      expect { SampleEmail.hello.deliver_now }.to raise_error(Isolator::MailerError)
    end
  end

  describe "#deliver_later" do
    specify do
      expect { SampleEmail.hello.deliver_later }.to raise_error(Isolator::BackgroundJobError)
    end
  end
end
