# frozen_string_literal: true

require "spec_helper"

describe "Sniffer adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#store" do
    specify do
      expect { Sniffer.store(Sniffer::DataItem.new(request: Sniffer::DataItem::Request.new(host: "example.com", port: 80, query: "/test.php", method: "GET"))) }.to raise_error(Isolator::HTTPError, %r{GET example.com:80/test.php})
    end
  end
end
