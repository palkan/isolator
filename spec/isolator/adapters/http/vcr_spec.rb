# frozen_string_literal: true

require "spec_helper"

describe "VCR adapter" do
  let(:uri) { URI.parse("http://localhost:4567/?lang=ruby&author=matz") }

  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#get" do
    specify do
      VCR.use_cassette "example" do
        expect { Net::HTTP.get(uri) }.to raise_error(Isolator::HTTPError, %r{GET http://localhost:4567/\?author=matz&lang=ruby})
      end
    end
  end
end
