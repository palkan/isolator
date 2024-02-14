# frozen_string_literal: true

require "spec_helper"

describe "ActionCable adapter" do
  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  describe "#broadcast" do
    specify do
      expect { ActionCable::Server::Base.new.broadcast("channel", "message") }.to raise_error(Isolator::WebsocketError, /channel/)
    end
  end
end
