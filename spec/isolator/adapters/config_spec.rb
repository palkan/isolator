# frozen_string_literal: true

require "spec_helper"

describe Isolator::Adapters::Config do
  subject { described_class.new }

  let(:adapter) { double(id: :sidekiq) }
  before { subject.register adapter.id, adapter }

  it "responds to sidekiq and returns the registered adapter" do
    expect(subject.sidekiq).to eq adapter
  end

  it "allows to use index by adapter id" do
    expect(subject[:sidekiq]).to eq adapter
  end

  it "raises KeyError when try to get unregistered adapter config" do
    expect { subject.not_sidekiq }.to raise_error KeyError
  end

  it "respondes to respond_to?" do
    expect(subject.respond_to?(:sidekiq)).to eq true
    expect(subject.respond_to?(:not_sidekiq)).to eq false
  end

  it "enumerates with each (f.e. using map)" do
    adapters_hash = Hash[subject.map { |k, v| [k, v] }]
    expect(adapters_hash).to eq("sidekiq" => adapter)
  end
end
