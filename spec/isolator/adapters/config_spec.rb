# frozen_string_literal: true

require "spec_helper"

describe Isolator::Adapters::Config do
  subject { described_class.new }

  let(:adapter) { double(id: :sidekiq) }
  before { subject.register adapter.id, adapter }

  it "responds to sidekiq and returns the registered adapter" do
    expect(subject.sidekiq).to eq adapter
  end

  it "enumerates with each (f.e. using map)" do
    adapters_hash = Hash[subject.map { |k, v| [k, v] }]
    expect(adapters_hash).to eq(sidekiq: adapter)
  end
end
