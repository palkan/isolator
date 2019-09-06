# frozen_string_literal: true

require "spec_helper"

describe "Net HTTP integration" do
  let(:uri) { URI.parse("http://localhost:4567/?lang=ruby&author=matz") }

  before do
    Sniffer.enable!
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  around do |ex|
    sniffer_was_enabled = Sniffer.enabled?
    Sniffer.enable!
    ex.run
    Sniffer.disable! unless sniffer_was_enabled
  end

  describe "#get" do
    specify do
      expect { Net::HTTP.get(uri) }.to raise_error(Isolator::HTTPError, %r{GET localhost:4567/\?lang=ruby&author=matz})
    end
  end
end
