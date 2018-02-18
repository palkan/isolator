# frozen_string_literal: true

require "spec_helper"

describe "Base adapter" do
  before(:all) do
    module ::Isolator::Danger # rubocop:disable Style/ClassAndModuleChildren
      def self.call(a, b)
        a + b
      end
    end

    Isolator.isolate :test, ::Isolator::Danger.singleton_class, :call
  end

  after(:all) do
    Isolator.send(:remove_const, "Danger")
    Isolator.adapters.delete(:test)
  end

  before do
    allow(Isolator).to receive(:within_transaction?) { true }
  end

  subject { ::Isolator::Danger }

  specify do
    expect { subject.call(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
  end

  describe "#ignore_if" do
    before(:all) do
      Isolator.adapters.test.ignore_if do |a, b|
        (a + b).even?
      end
    end

    after(:all) do
      Isolator.adapters.test.ignores.clear
    end

    it "raises when not ignored" do
      expect { subject.call(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    end

    it "doesn't raise when ignored" do
      expect { subject.call(3, 5) }.not_to raise_error
    end
  end
end
