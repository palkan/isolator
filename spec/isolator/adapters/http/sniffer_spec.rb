# frozen_string_literal: true

require "spec_helper"

describe "Sniffer adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#store" do
    specify do
      expect { Sniffer.store(Sniffer::DataItem.new) }.to raise_error(Isolator::HTTPError)
    end
  end
end
