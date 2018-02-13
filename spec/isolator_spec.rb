require 'spec_helper'

RSpec.describe Isolator do
  subject { described_class }

  describe '.configure' do
    before do
      described_class.configure do |configuration|
        configuration.raise_errors = true
        configuration.logger = true
      end
    end

    it 'sets raise_errors option properly' do
      expect(described_class.configuration.raise_errors).to eq true
    end

    it 'sets logger option properly' do
      expect(described_class.configuration.logger).to eq true
    end
  end
end
