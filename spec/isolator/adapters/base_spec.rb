# frozen_string_literal: true

require "spec_helper"

describe "Base adapter" do
  before(:all) do
    class ::Isolator::Danger # rubocop:disable Lint/ConstantDefinitionInBlock
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

  describe "#ignore_target?" do
    before(:all) do
      class ::Isolator::Danger # rubocop:disable Lint/ConstantDefinitionInBlock
        attr_reader :role

        def initialize(role)
          @role = role
        end

        def perform(a, b)
          a + b
        end
      end

      Isolator.isolate :test_instance, target: ::Isolator::Danger,
        method_name: :perform, ignore_on: ->(obj) { obj.role == :read }
    end

    after(:all) do
      Isolator.adapters.delete(:test_instance)
    end

    let(:role) { :write }

    subject { ::Isolator::Danger.new(role) }

    specify do
      expect { subject.perform(1, 2) }.to raise_error(Isolator::UnsafeOperationError)
    end

    context "when ignored" do
      let(:role) { :read }

      specify do
        expect { subject.perform(1, 2) }.not_to raise_error
      end
    end
  end
end
