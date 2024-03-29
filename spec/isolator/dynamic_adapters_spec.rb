# frozen_string_literal: true

require "spec_helper"

RSpec.describe Isolator, "dynamic adapters" do
  let(:example_class) do
    Class.new {
      def test
        42
      end

      def sum(a, b)
        a + b
      end

      def round(num, precision: 0)
        num.round(precision)
      end

      def shout
        yield.upcase
      end
    }
  end

  before do
    Isolator.remove_adapter(:foo)
  end

  def within_transaction
    Isolator.incr_transactions!
    yield
  ensure
    Isolator.decr_transactions!
  end

  it "checks that the specified method is not called inside a transaction" do
    expect(Isolator.has_adapter?(:foo)).to eq(false)
    Isolator.isolate(:foo, target: example_class, method_name: :test)

    expect(Isolator.has_adapter?(:foo)).to eq(true)
    expect(example_class.new.test).to eq(42)

    within_transaction do
      expect {
        example_class.new.test
      }.to raise_error(Isolator::UnsafeOperationError)
    end
  end

  it "restores original method when removed" do
    Isolator.isolate(:foo, target: example_class, method_name: :test)

    within_transaction do
      expect {
        example_class.new.test
      }.to raise_error(Isolator::UnsafeOperationError)
    end

    Isolator.remove_adapter(:foo)

    within_transaction do
      expect {
        example_class.new.test
      }.not_to raise_error
    end
  end

  it "does nothing when removing non-existing adapter" do
    expect {
      Isolator.remove_adapter(:foo)
    }.not_to raise_error
  end

  it "supports arguments in the modified method" do
    Isolator.isolate(:foo, target: example_class, method_name: :sum)
    expect(example_class.new.sum(10, 25)).to eq(35)
  end

  it "supports keyword arguments in the modified method" do
    Isolator.isolate(:foo, target: example_class, method_name: :round)

    expect(example_class.new.round(0.05)).to eq(0)
    expect(example_class.new.round(0.05, precision: 1)).to eq(0.1)
  end

  it "supports blocks in the modified method" do
    Isolator.isolate(:foo, target: example_class, method_name: :shout)

    expect(example_class.new.shout { "hello" }).to eq("HELLO")
  end
end
