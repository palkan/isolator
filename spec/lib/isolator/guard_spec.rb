# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isolator::Guard do
  before { Isolator.enable! }

  subject { described_class.new(object: record, conditions: conditions).notify? }

  context "with proc conditions" do
    let(:record) {}

    context "with if" do
      let(:conditions) do
        { if: -> { false } }
      end

      it { is_expected.to eq false }
    end

    context "with unless" do
      let(:conditions) do
        { unless: -> { true } }
      end

      it { is_expected.to eq false }
    end
  end

  context "with method names" do
    let(:record) { double(test?: true) }

    let(:conditions) { { if: :test? } }

    it { is_expected.to eq true }
  end
end
