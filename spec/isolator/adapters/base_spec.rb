# frozen_string_literal: true

require "spec_helper"

describe "Base adapter" do
  before(:all) do
    module ::Isolator::Danger # rubocop:disable Lint/ConstantDefinitionInBlock
      def self.call(a, b, method: :+)
        a.send(method, b)
      end
    end

    Isolator.isolate :test, target: ::Isolator::Danger.singleton_class,
                            method_name: :call
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
    after do
      Isolator.adapters.test.ignores.clear
    end

    it "doesn't raise when ignored" do
      Isolator.adapters.test.ignore_if do |a, b, method: :+|
        method == :+ || a == 1
      end

      expect {
        subject.call(1, 2)
      }.not_to raise_error

      expect {
        subject.call(2, 2, method: :*)
      }.to raise_error(Isolator::UnsafeOperationError)

      expect {
        subject.call(2, 2, method: :+)
      }.not_to raise_error
    end
  end
end
