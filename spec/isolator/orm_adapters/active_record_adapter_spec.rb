# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::Base do
  describe ".transaction" do
    context "when making network request" do
      subject(:make_request) do
        described_class.transaction do
          HTTP.get("http://example.com")
        end
      end

      it { expect { make_request }.to raise_error(Isolator::NetworkRequestError) }
    end
  end
end
